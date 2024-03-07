log.info("shell -- file -- mqtt_send -- start")
-- sys库是标配
_G.sys = require("sys")

--联网状态  开机未联网 0  开机联网 1  连上服务器 2
local  mqtt_connect_flag = 0
local function get_mqtt_connect_flag()
    return mqtt_connect_flag
end
--联网状态  未重连 0  重连 1 
local  mqtt_reconnect_flag = 0
local  Device_SN      = fskv.get("Device_SN")

-- 用户上传状态数据统一格式
local function Device_Get_UserData(Myid, Mysn, MyCmd, Mychx, Mydata, Mystatus, Mytag)
    local torigin = 
    {
        ID      = Myid, 
        SN      = Mysn, 
        Cmd     = MyCmd, 
        Chx     = Mychx, 
        Data    = Mydata,
        Status  = Mystatus,
        Tag     = Mytag,
    }
    local msg = json.encode(torigin)
    return msg
end
-----------------------------------------------
-----------------------------------------------
local mqtt_lat = ""
local mqtt_lng = ""

local mqttc = "0" -- 重连标志 0 开机  1 重连

local function get_mqttc()
    return mqttc
end


local function Device_Get_Info()
    local torigin =
    {
        Vendor = "66",
        Category = "Controller",
        Module = "XLK8020",
        Chxs = "4",
        HW = "V1.0",
        FW = "V2024.03.6.10",
        IMEI = mobile.imei(),
        IMSI = mobile.imsi(),
        LBS= tostring(mqtt_lat).."_"..tostring(mqtt_lng) ,
        ICCID = mobile.iccid(),
        RSSI = tostring(mobile.csq()),
        Temp=string.format("%0.2f",(math.floor(100 * tonumber(_adc.Get_Temperature())) / 100)),
    }
    local msg = json.encode(torigin)
    return msg
end
-----------------------------------------------
---------------发送报警信息给服务器
local function DeviceWarn_Status(Mycmd, Mychx, Mydata, Mystatus, Mytag) -- 供别处调用
    if mqtt_connect_flag ~= 2 then return end
    if (fskv.get("LOCK_FLAG") == "1") then
        sys.publish("mqtt_send",Device_Get_UserData("DeviceWarn", Device_SN,"Lock", 0, "1", "", ""))
    elseif (fskv.get("LOCK_FLAG") == "0") then
        sys.publish("mqtt_send",Device_Get_UserData("DeviceWarn", Device_SN,Mycmd, Mychx, Mydata, Mystatus, Mytag))
    end
end

---------------发送回复信息给服务器
local function DeviceResponse_Status(Mycmd, Mychx, Mydata, Mystatus, Mytag) -- 供别处调用
    if mqtt_connect_flag == 1 or mqtt_connect_flag == 2 then 
        sys.publish("mqtt_send",Device_Get_UserData("DeviceResponse", Device_SN , Mycmd, Mychx, Mydata, Mystatus, Mytag))
    end
end

----------信号强度，有报警则发送信息给服务器-5分钟扫描一次
local function Loop_Update_Device_csq()
    DeviceResponse_Status("Rssi", 0,  tostring(mobile.csq()), "", "")
end

----------电磁阀状态，有报警则发送信息给服务器-5分钟扫描一次
local function Loop_Update_Elec_Status()
    for i = 1,4,1 do
        --20240306
        --业务分层逻辑
        --在此，需要测量继电器的操作，【（1，提出操作请求，并附带自身状态）---->（2，处理队列）---->（3，根据状态信息做出具体操作）】
        --例如，这里的逻辑是当电磁阀处于关闭状态，则无需测量与上报电磁阀状态，原本在【1约束】，现在改为【3约束】
        sys.publish("BL6552_Chx","GetChx", i, _led.Get_Electromagnetic_ChX(i), "0") -- 插入中断事件BL6552_Chx(Event,Chx,Tag)
    end    
end

----------温度状态，有报警则发送信息给服务器-5分钟扫描一次
local function Loop_Update_Temperature_Status()
        DeviceResponse_Status("Temp", 0,_adc.Get_Temperature(), "", "")  
        -- 检测板子温度是否报警
        if tonumber(fskv.get("TEMPERATURE_NUM_CONFIG")) <= (math.floor(100 * tonumber(_adc.Get_Temperature())) / 100) then
            sys.publish("DeviceWarn_Status","Alert_Hot", 0, string.format("%.2f",(math.floor(100 * tonumber(_adc.Get_Temperature())) / 100)), "", "")
            for i = 1,4,1 do
                if _led.Get_Electromagnetic_ChX(i) == 1 then --电磁阀开启菜上报数据
                    sys.publish("LED_Chx","AlertOP",i,0)
                end
            end 
        end
end

local function Loop_Update_Task() -- 每隔一段时间定时上报CHx数据
    while true do
        log.info("Loop_Update_Task: start")
        log.info("mqtt_connect_flag:",mqtt_connect_flag,"\n")
        if mqtt_connect_flag == 2 then
            Loop_Update_Device_csq()
            Loop_Update_Elec_Status()
            Loop_Update_Temperature_Status()
            sys.wait(299000) -- 总延时5min
        end
        sys.wait(1000) -- 总延时5min
    end
end

local function Loop_Update_Action_Task() -- 每隔一段时间定时上报CHx数据
    while true do
        if mqtt_connect_flag == 2 then
            DeviceResponse_Status("Hb", 0, "", "", "") 
            sys.wait(119000)
        end
        sys.wait(1000) -- 总延时2min
    end
end

-- mqtt握手
sys.taskInit( function() --设备连接mqtt后，进行握手
    
    mqtt_connect_flag = 0
    
    sys.waitUntil("IP_READY")
    while true do
        mqtt_connect_flag = 1
        log.info("mqtt_connect_flag = ",mqtt_connect_flag)--测试
        sys.waitUntil("mqtt_conack")
        if mqtt_connect_flag == 1 then
            -- 握手信息
            DeviceResponse_Status("Reg", 0, "", mqttc, "0") 
            sys.wait(5000)
            -- 硬件消息
            DeviceResponse_Status("Reg", 0,Device_Get_Info(), mqttc, "2")
            sys.wait(5000)
            -- 心跳消息
            DeviceResponse_Status("Hb", 0, "", mqttc, "")
            sys.wait(5000)
            --SET_Self_Check
            if (fskv.get("LOCK_FLAG") == "1") then 
                sys.publish("DeviceWarn_Status","Lock", 0, "1", "", "")
            end
            mqtt_connect_flag = 2 -- 连接 - 握手成功
            sys.publish("mqtt_connect_flag",mqtt_connect_flag)
            log.debug("---------------------------------mqtt_connect_flag = ",mqtt_connect_flag)--测试
            sys.waitUntil("mqtt_recon")  --系统断网重连
            mqttc = "1"
        end
        
    end
end)

sys.taskInit(function ()
    while true do
        local res, data, lat, lng = sys.waitUntil("lbsloc_result")
        log.info("------xxxxxx----", res, data, lat, lng)
        if data == 0 then 
            mqtt_lat = lat
            mqtt_lng = lng
        end
        log.info("lua", rtos.meminfo())
        log.info("sys", rtos.meminfo("sys"))
        log.info("SN", SN)
    end
end)

sys.taskInit(Loop_Update_Task)
sys.taskInit(Loop_Update_Action_Task)

---------------------------------- 【接收】外部事件 ----------------------------------
--上报和回复事件
sys.taskInit(function ()
    while true do
        local res, Mycmd, Mychx, Mydata, Mystatus, Mytag = sys.waitUntil("DeviceResponse_Status")
        if res then
            DeviceResponse_Status(Mycmd, Mychx, Mydata, Mystatus, Mytag)
        end
    end
end)

--告警事件
sys.taskInit(function ()
    while true do
        local res, Mycmd, Mychx, Mydata, Mystatus, Mytag = sys.waitUntil("DeviceWarn_Status")
        if res then
            if Mycmd == "Alert_PowerLost" then --设备掉电告警特殊处理
                sys.publish("mqtt_send",Device_Get_UserData("DeviceWarn", Device_SN,Mycmd, Mychx, Mydata, Mystatus, Mytag))
                return true
            end
            DeviceWarn_Status(Mycmd, Mychx, Mydata, Mystatus, Mytag)
        end
    end
end)

log.info("shell -- file -- mqtt_send -- end")
-- 用户代码已结束---------------------------------------------
------供外部文件调用的函数
return {
    DeviceWarn_Status = DeviceWarn_Status,
    DeviceResponse_Status = DeviceResponse_Status,
    get_mqttc = get_mqttc,
    get_mqtt_connect_flag = get_mqtt_connect_flag,
}
