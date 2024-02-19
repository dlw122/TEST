log.info("shell -- file -- mqtt_send -- start")
-- sys库是标配
_G.sys = require("sys")

--联网状态  开机未联网 0  开机联网 1  连上服务器 2
local  mqtt_connect_flag = 0
--联网状态  未重连 0  重连 1 
local  mqtt_reconnect_flag = 0
local  Device_SN      = "66666666"

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
local function Device_Get_Info()
    local torigin =
    {
        Vendor = "66",
        Category = "Controller",
        Module = "XLK8020",
        Chxs = "4",
        IOs = "2",
        HW = "V1.00",
        FW = "V2024.01.14_test_1",
        IMEI = mobile.imei(),
        IMSI = mobile.imsi(),
        LBS= mqtt_lat.."_"..mqtt_lng ,
        ICCID = mobile.iccid(),
        RSSI = mobile.csq(),
        Temp="29.98",
        BT="1",
    }
    local msg = json.encode(torigin)
    return msg
end
-----------------------------------------------
---------------发送报警信息给服务器
local function DeviceWarn_Status(Mycmd, Mychx, Mydata, Mystatus, Mytag) -- 供别处调用
    if mqtt_connect_flag ~= 2 then return end
    if (_key_irq.get_lock_enable_flag() == 1) then
        sys.publish("mqtt_send",Device_Get_UserData("DeviceWarn", Device_SN,"LOCK", 0, 0))
    elseif (_key_irq.get_lock_enable_flag() == 0) then
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
    DeviceResponse_Status("Rssi", 0,  mobile.csq(), "", "")
end

----------电磁阀状态，有报警则发送信息给服务器-5分钟扫描一次
local function Loop_Update_Elec_Status()
    for i = 1,4,1 do
        sys.publish("BL6552_Chx","GetChx", 1, _led.Get_Electromagnetic_ChX(i), "0") -- 插入中断事件BL6552_Chx(Event,Chx,Tag)
    end
end

----------温度状态，有报警则发送信息给服务器-5分钟扫描一次
local function Loop_Update_Temperature_Status()
        DeviceResponse_Status("Temp", 0,_adc.Get_Temperature(), "", "")  
        -- 检测板子温度是否报警
        if tonumber(fskv.get("TEMPERATURE_NUM_CONFIG")) <= (math.floor(100 * tonumber(_adc.Get_Temperature())) / 100) then
            sys.publish("DeviceWarn_Status","Alert_TF", Chx, tostring((math.floor(100 * tonumber(_adc.Get_Temperature())) / 100)), "", "")
            sys.publish("DeviceWarn_Status","Alert_TF", Chx, tostring((math.floor(100 * tonumber(_adc.Get_Temperature())) / 100)), "", "")
            sys.publish("DeviceWarn_Status","Alert_TF", Chx, tostring((math.floor(100 * tonumber(_adc.Get_Temperature())) / 100)), "", "")
            sys.publish("DeviceWarn_Status","Alert_TF", Chx, tostring((math.floor(100 * tonumber(_adc.Get_Temperature())) / 100)), "", "")
            sys.publish("LED_Chx","AlertOP",1,0)
            sys.publish("LED_Chx","AlertOP",2,0)
            sys.publish("LED_Chx","AlertOP",3,0)
            sys.publish("LED_Chx","AlertOP",4,0)

        end
end

local function Loop_Update_Task() -- 每隔一段时间定时上报CHx数据
    while true do
        print("Loop_Update_Task:".."\n")
        print("mqtt_connect_flag:",mqtt_connect_flag,"\n")
        if mqtt_connect_flag == 2 then
            Loop_Update_Device_csq()
            Loop_Update_Elec_Status()
            Loop_Update_Temperature_Status()
        end
        sys.wait(300000) -- 总延时5min
    end
end

local function Loop_Update_Action_Task() -- 每隔一段时间定时上报CHx数据
    while true do
        sys.wait(120000)
        if mqtt_connect_flag == 2 then
            DeviceResponse_Status("Hb", 0, "", "", "") 
        end
    end
end

-- mqtt握手
sys.taskInit( function() --设备连接mqtt后，进行握手
    mqtt_connect_flag = 0
    sys.waitUntil("IP_READY")
    while true do

        mqtt_connect_flag = 1
        sys.waitUntil("mqtt_conack")
        if mqtt_connect_flag == 1 then
            -- 握手信息
            DeviceResponse_Status("Reg", 0, "", "", "0") 
            sys.wait(5000)
            -- 硬件消息
            DeviceResponse_Status("Reg", 0,Device_Get_Info(), "", "2")
            sys.wait(5000)
            -- 心跳消息
            DeviceResponse_Status("Hb", 0, "", "", "")
            sys.wait(5000)
            --SET_Self_Check
            if (fskv.get("LOCK_FLAG") == 1) then 
                sys.publish("DeviceWarn_Status","Lock", 0, "1", "", "")
            end
            mqtt_connect_flag = 2 -- 连接 - 握手成功
            sys.publish("mqtt_connect_flag",mqtt_connect_flag)
            print("---------------------------------------------------mqtt_connect_flag = ",mqtt_connect_flag)--测试
            sys.waitUntil("mqtt_recon")  --系统断网重连
        end
        
    end
end)

sys.taskInit(function ()
    while true do
        sys.wait(3000)
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
}
