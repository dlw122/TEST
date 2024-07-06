log.info("shell -- file -- _init -- start")

-- 初始化保存数据的文件

sys.taskInit(function()
    -- 检查一下当前固件是否支持fskv
    if not fskv then
        log.info("fskv", "this demo need fskv")
        return
    end

    -- 初始化kv数据库
    if fskv.init("config.lua") == false then
        log.debug("fdb", "kv数据库初始化失败!")
    end
    
    local bootime = fskv.get("boottime")
    if bootime == nil or type(bootime) ~= "number" then
        bootime = 0
    else
        bootime = bootime + 1
    end
    fskv.set("boottime", bootime)
    log.info("fskv-------------------------------------", fskv.get("boottime"))

    local check = fskv.get("check")
    
    -- if fskv.get("Device_SN") == nil then
    --     fskv.set("Device_SN", "22222222")
    -- end
    if check == "check_OK" then
        log.info("fskv------------",fskv.get("check"))
    else
        fskv.set("check", "check_OK")
        fskv.set("Device_SN", "60975340")
        fskv.set("I_SCALE_ENABLE_CHX_CONFIG", {_1 = "1",_2 = "1",_3 = "1",_4 = "1"})
        fskv.set("I_SCALE_NUM_CHX_CONFIG",{_1 = "40",_2 = "40",_3 = "40",_4 = "40"})
        fskv.set("I_NUM_CHX_CONFIG", {_1 = "6",_2 = "6",_3 = "6",_4 = "6"})
        fskv.set("V_NUM_CHX_CONFIG",{_1 = "430",_2 = "430",_3 = "430",_4 = "430"})
        fskv.set("IV_NUM_ENABLE_CHX_CONFIG", {_1 = "1",_2 = "1",_3 = "1",_4 = "1"})
        fskv.set("ZXTO_ENABLE_CHX_CONFIG",{_1 = "1",_2 = "1",_3 = "1",_4 = "1"})
        fskv.set("VVVF_ENABLE_CHX_CONFIG", {_1 = "0",_2 = "0",_3 = "0",_4 = "0"})
        fskv.set("TEMPERATURE_NUM_CONFIG", "80.00")
        fskv.set("START_Time_CHX_CONFIG",  {_1 = "0",_2 = "0",_3 = "0",_4 = "0"})
        fskv.set("CLOSE_Time_CHX_CONFIG",  {_1 = "0",_2 = "0",_3 = "0",_4 = "0"})
        fskv.set("Time_ENABLE_CHX_CONFIG", {_1 = "0",_2 = "0",_3 = "0",_4 = "0"})
        fskv.set("POWER_CLOSE_ENABLE_CONFIG", "1")
        fskv.set("ElE_CHX", {_1 = "0",_2 = "0",_3 = "0",_4 = "0"})
        fskv.set("LOCK_FLAG", "0")
        fskv.set("TimeSync_CONFIG", "")
        log.info("fskv------------init!")
    end
    fskv.set("HW", "V01.1 ")
    fskv.set("FW", "V07.06")

    
    log.info("Device_SN                 ------------",fskv.get("Device_SN"))
    log.warn("I_SCALE_ENABLE_CHX_CONFIG ------------",fskv.get("I_SCALE_ENABLE_CHX_CONFIG")["_1"],fskv.get("I_SCALE_ENABLE_CHX_CONFIG")["_2"],fskv.get("I_SCALE_ENABLE_CHX_CONFIG")["_3"],fskv.get("I_SCALE_ENABLE_CHX_CONFIG")["_4"])
    log.warn("I_SCALE_NUM_CHX_CONFIG    ------------",fskv.get("I_SCALE_NUM_CHX_CONFIG")["_1"],fskv.get("I_SCALE_NUM_CHX_CONFIG")["_2"],fskv.get("I_SCALE_NUM_CHX_CONFIG")["_3"],fskv.get("I_SCALE_NUM_CHX_CONFIG")["_4"])
    log.warn("I_NUM_CHX_CONFIG          ------------",fskv.get("I_NUM_CHX_CONFIG")["_1"],fskv.get("I_NUM_CHX_CONFIG")["_2"],fskv.get("I_NUM_CHX_CONFIG")["_3"],fskv.get("I_NUM_CHX_CONFIG")["_4"])
    log.warn("V_NUM_CHX_CONFIG          ------------",fskv.get("V_NUM_CHX_CONFIG")["_1"],fskv.get("V_NUM_CHX_CONFIG")["_2"],fskv.get("V_NUM_CHX_CONFIG")["_3"],fskv.get("V_NUM_CHX_CONFIG")["_4"])
    log.warn("IV_NUM_ENABLE_CHX_CONFIG  ------------",fskv.get("IV_NUM_ENABLE_CHX_CONFIG")["_1"],fskv.get("IV_NUM_ENABLE_CHX_CONFIG")["_2"],fskv.get("IV_NUM_ENABLE_CHX_CONFIG")["_3"],fskv.get("IV_NUM_ENABLE_CHX_CONFIG")["_4"])
    log.warn("ZXTO_ENABLE_CHX_CONFIG    ------------",fskv.get("ZXTO_ENABLE_CHX_CONFIG")["_1"],fskv.get("ZXTO_ENABLE_CHX_CONFIG")["_2"],fskv.get("ZXTO_ENABLE_CHX_CONFIG")["_3"],fskv.get("ZXTO_ENABLE_CHX_CONFIG")["_4"])
    log.warn("VVVF_ENABLE_CHX_CONFIG    ------------",fskv.get("VVVF_ENABLE_CHX_CONFIG")["_1"],fskv.get("VVVF_ENABLE_CHX_CONFIG")["_2"],fskv.get("VVVF_ENABLE_CHX_CONFIG")["_3"],fskv.get("VVVF_ENABLE_CHX_CONFIG")["_4"])
    log.warn("TEMPERATURE_NUM_CONFIG    ------------",fskv.get("TEMPERATURE_NUM_CONFIG"))
    log.warn("START_Time_CHX_CONFIG     ------------",fskv.get("START_Time_CHX_CONFIG")["_1"],fskv.get("START_Time_CHX_CONFIG")["_2"],fskv.get("START_Time_CHX_CONFIG")["_3"],fskv.get("START_Time_CHX_CONFIG")["_4"])
    log.warn("CLOSE_Time_CHX_CONFIG     ------------",fskv.get("CLOSE_Time_CHX_CONFIG")["_1"],fskv.get("CLOSE_Time_CHX_CONFIG")["_2"],fskv.get("CLOSE_Time_CHX_CONFIG")["_3"],fskv.get("CLOSE_Time_CHX_CONFIG")["_4"])
    log.warn("Time_ENABLE_CHX_CONFIG    ------------",fskv.get("Time_ENABLE_CHX_CONFIG")["_1"],fskv.get("Time_ENABLE_CHX_CONFIG")["_2"],fskv.get("Time_ENABLE_CHX_CONFIG")["_3"],fskv.get("Time_ENABLE_CHX_CONFIG")["_4"])
    log.warn("POWER_CLOSE_ENABLE_CONFIG ------------",fskv.get("POWER_CLOSE_ENABLE_CONFIG"))
    log.warn("ElE_CHX                   ------------",fskv.get("ElE_CHX")["_1"],fskv.get("ElE_CHX")["_2"],fskv.get("ElE_CHX")["_3"],fskv.get("ElE_CHX")["_4"])
    log.warn("LOCK_FLAG                 ------------",fskv.get("LOCK_FLAG"))
    log.warn("TimeSync_CONFIG           ------------",fskv.get("TimeSync_CONFIG"))
end)


log.info("shell -- file -- _init -- end")
