log.info("shell -- file -- mqtt_handle -- start")

--------------------------------------------------------------
local Device_SN = "66666666"
-- OTA更新回调函数
local function fota_cb(ret)
    log.info("fota", ret)
    if ret == 0 then
        rtos.reboot()
    end
end

local function Mqtt_Handle_Control(tjsondata)
    if tjsondata["Chx"] ~= 0 then return end
    if tjsondata["Cmd"] == "Reg" and tjsondata["Data"] == 0 then --
        sys.publish("DeviceResponse_Status","Reg", 0, "", "", "1")

    -------------------------------------------服务器控制按键
    elseif tjsondata["Cmd"] == "SvrOP" then --
        sys.publish("LED_Chx","SvrOP",tjsondata["Chx"], tonumber(tjsondata["Data"]))
        sys.publish("DeviceResponse_Status","SvrOP", tjsondata["Chx"], tjsondata["Data"], "", "")

    -------------------------------------------更新
    elseif tjsondata["Cmd"] == "Update" then --
        sys.publish("DeviceResponse_Status","Update", 0, "", "", "")
        libfota.request(fota_cb, tjsondata["Data"])
        
    -------------------------------------------重启
    elseif tjsondata["Cmd"] == "Restart" then --
        sys.publish("DeviceResponse_Status","Restart", 0, "", "", "")
        rtos.reboot()
        
    -------------------------------------------复位
    elseif tjsondata["Cmd"] == "Reset" then --
        for i = 1,4,1 do
            fskv.sett("I_SCALE_NUM_CHX_CONFIG", 1,"50")
            fskv.sett("I_NUM_CHX_CONFIG",  1,"20")
            fskv.sett("V_NUM_CHX_CONFIG",  1,"250")
            fskv.sett("I_SCALE_ENABLE_CHX_CONFIG",  1,"1")
            fskv.sett("IV_NUM_ENABLE_CHX_CONFIG",  1,"1")
            fskv.sett("ZXTO_ENABLE_CHX_CONFIG",  1,"1")
            fskv.sett("VVVF_ENABLE_CHX_CONFIG",  1,"0")
            fskv.sett("Time_ENABLE_CHX_CONFIG",  1,"0")
            fskv.sett("ANGLE_ENABLE_CHX_CONFIG",  1,"0")
        end

        fskv.set("TEMPERATURE_NUM_CONFIG", "80.00")
        fskv.set("POWER_CLOSE_ENABLE_CONFIG","1")

        sys.publish("DeviceResponse_Status","Reset", 0, "", "", "")
    end
end

local function Mqtt_Handle_Set_up(tjsondata)
    -------------------------------------------设置电压阈值
    if tjsondata["Cmd"] == "Prof_MaxVolt" then --
        fskv.sett("V_NUM_CHX_CONFIG", tjsondata["Chx"],tjsondata["Data"])
        _bl6552_spi.BL6552_Init(tjsondata["Chx"]) --重新初始化BL6552 
        -- 状态改变即刻读取数据
        sys.publish("DeviceResponse_Status","Prof_MaxVolt", tjsondata["Chx"], tjsondata["Data"], "", "")
    -------------------------------------------设置电流阈值
    elseif tjsondata["Cmd"] == "Prof_MaxAmp" then --
        fskv.sett("I_NUM_CHX_CONFIG", tjsondata["Chx"],tjsondata["Data"])
        _bl6552_spi.BL6552_Init(tjsondata["Chx"]) 
        sys.publish("DeviceResponse_Status","Prof_MaxAmp", tjsondata["Chx"], tjsondata["Data"], "", "")
    -------------------------------------------设置非变频/变频    0   /   1
    elseif tjsondata["Cmd"] == "Prof_VVVF" then --
        fskv.sett("VVVF_ENABLE_CHX_CONFIG", tjsondata["Chx"], tjsondata["Data"])
        sys.publish("DeviceResponse_Status","Prof_VVVF", tjsondata["Chx"], tjsondata["Data"], "", "")
    -------------------------------------------设置电流比例
    elseif tjsondata["Cmd"] == "Prof_MaxSCALE" then -- 设置电流比例
        fskv.sett("I_SCALE_NUM_CHX_CONFIG", tjsondata["Chx"], tjsondata["Data"])
        -- 状态改变即刻读取数据
        sys.publish("BL6552_Chx","GetChx", tjsondata["Chx"], _led.Get_Electromagnetic_ChX(i), "0")
        sys.publish("DeviceResponse_Status","Prof_MaxSCALE", tjsondata["Chx"], tjsondata["Data"], "", "")
    -------------------------------------------设置温度阈值
    elseif tjsondata["Cmd"] == "Prof_MaxTemp" then
        fskv.set("TEMPERATURE_NUM_CONFIG", tjsondata["Data"])
        -- 检测板子温度是否报警
        if tonumber(fskv.get("TEMPERATURE_NUM_CONFIG")) <= (math.floor(100 * tonumber(_adc.Get_Temperature())) / 100) then
            _led.Set_Electromagnetic_ChX(1, 0)
            sys.publish("DeviceWarn_Status","AlertOP", 1, "", "", "")
            _led.Set_Electromagnetic_ChX(2, 0)
            sys.publish("DeviceWarn_Status","AlertOP", 2, "", "", "")
            _led.Set_Electromagnetic_ChX(3, 0)
            sys.publish("DeviceWarn_Status","AlertOP", 3, "", "", "")
            _led.Set_Electromagnetic_ChX(4, 0)
            sys.publish("DeviceWarn_Status","AlertOP", 4, "", "", "")
        end
        sys.publish("DeviceResponse_Status","Prof_MaxTemp", tjsondata["Chx"], tjsondata["Data"], "", "")
    -------------------------------------------定时
    elseif tjsondata["Cmd"] == "Prof_TimeOn" then
        if string.len(tjsondata["Data"]) % 16 == 0 then -- 接收的数据检验
            fskv.sett("START_Time_CHX_CONFIG", tjsondata["Chx"],tjsondata["Data"])
        end

        sys.publish("DeviceResponse_Status","Prof_TimeOn", tjsondata["Chx"], tjsondata["Data"], "", "")
    elseif tjsondata["Cmd"] == "Prof_TimeOff" then --
        if string.len(tjsondata["Data"]) % 16 == 0 then
            fskv.sett("CLOSE_Time_CHX_CONFIG", tjsondata["Chx"],tjsondata["Data"])
        end
        sys.publish("DeviceResponse_Status","Prof_TimeOff", tjsondata["Chx"], tjsondata["Data"], "", "")
    end
end

local function Mqtt_Handle_Enable(tjsondata)
    ------------------------------------------- 电流比例使能选项
    if tjsondata["Cmd"] == "Prof_SCALE" and (tjsondata["Data"] == "1" or tjsondata["Data"] =="0") then 
        fskv.sett("I_SCALE_ENABLE_CHX_CONFIG", tjsondata["Chx"], tjsondata["Data"])
        -- 使能状态改变即可读取数据
        _bl6552_data.BL6552_Chx("Update",tjsondata["Chx"],"0")
        sys.publish("DeviceResponse_Status","Prof_SCALE", tjsondata["Chx"], tjsondata["Data"], "", "")
    ------------------------------------------- 定时器使能选项
    elseif tjsondata["Cmd"] == "Prof_Time" then --
        fskv.sett("Time_ENABLE_CHX_CONFIG", tjsondata["Chx"], tjsondata["Data"])
        sys.publish("DeviceResponse_Status","Prof_Time", tjsondata["Chx"], tjsondata["Data"], "", "")
    -------------------------------------------掉电告警是否开启
    elseif tjsondata["Cmd"] == "Prof_PowerLost" then
        fskv.set("POWER_CLOSE_ENABLE_CONFIG",tjsondata["Data"])
        sys.publish("DeviceResponse_Status","Prof_PowerLost", tjsondata["Chx"], tjsondata["Data"], "", "")
    -------------------------------------------最大电流电压是否开启
    elseif tjsondata["Cmd"] == "Prof_IV" then -- 最大电流，电压是否开启
        fskv.sett("IV_NUM_ENABLE_CHX_CONFIG", tjsondata["Chx"], tjsondata["Data"])
        -- 使能状态改变即可读取数据
        sys.publish("BL6552_Chx","Update",tjsondata["Chx"],"0")
        sys.publish("DeviceResponse_Status","Prof_IV", tjsondata["Chx"], tjsondata["Data"], "", "")
    -------------------------------------------缺相是否开启
    elseif tjsondata["Cmd"] == "Prof_ZXTO" then -- 缺相
        fskv.sett("ZXTO_ENABLE_CHX_CONFIG", tjsondata["Chx"], tjsondata["Data"])
        -- 使能状态改变即可读取数据
        sys.publish("BL6552_Chx","Update",tjsondata["Chx"],"0","")     
        sys.publish("DeviceResponse_Status","Prof_ZXTO", tjsondata["Chx"], tjsondata["Data"], "", "")
    end
end

local function Mqtt_Handle_Lock(tjsondata)
    print("Mqtt_Handle_Lock \r\n")
    print("SN = ", tjsondata["SN"])
    print("Cmd = ", tjsondata["Cmd"])
    print("Data = ", tjsondata["Data"])
    Mqtt_Handle_Control(tjsondata)
    Mqtt_Handle_Set_up(tjsondata)
    Mqtt_Handle_Enable(tjsondata)
    
end

--------------------------------------------------------------
local function Mqtt_Handle_Device(tjsondata)
    if ( _key_irq.Get_lock_enable_flag() == 1) then
        sys.publish("DeviceWarn_Status","Lock", 0, 1, "", "")
    elseif  _key_irq.Get_lock_enable_flag()  == 0 then
        Mqtt_Handle_Lock(tjsondata)
    end
end

--------------------------------------------------------------
local function Mqtt_Handle_TimeSync(data)
    fskv.set("TimeSync_CONFIG", tjsondata["Data"])

    if string.len(tjsondata["Data"]) == 19 then
        sys.publish("TimeSync",tjsondata["Data"]) -- 系统时间已经同步
    end
end



--------------------------------------------------------------
local function Mqtt_Handle(tjsondata)
-------------------------------------------与服务器时间同步
    if tjsondata["Cmd"] == "TimeSync" then --
        Mqtt_Handle_TimeSync(tjsondata)
        return
    end

    if tjsondata["SN"] == Device_SN then
        if(tjsondata["Chx"] == 0 or tjsondata["Chx"] == 1 or tjsondata["Chx"] == 2 or tjsondata["Chx"] == 3 or tjsondata["Chx"] == 4) then -- 设备ID
            Mqtt_Handle_Device(tjsondata)
        end
    end
end

sys.taskInit(function()
    while true do
        local res, data = sys.waitUntil("mqtt_payload")
            log.info("接收到的数据 - ", "res = ", res, "data = ", data)
			if res == true then 
				-- json格式传输
				local tjsondata, jsonresult, errinfo = json.decode(data)
				if jsonresult then
					-------------------------------------------
					-------------------------------------------更新
					Mqtt_Handle(tjsondata)
				end
			end
    end
end)

log.info("shell -- file -- mqtt_handle -- end")
-- 用户代码已结束---------------------------------------------
------供外部文件调用的函数
return {
    Mqtt_Handle = Mqtt_Handle,
}
