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
        log.warn("fdb", "kv数据库初始化失败!")
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
    fskv.set("Device_SN", "00000001")
    if check == "check_OK" then
        log.info("fskv------------",fskv.get("check"))
    else
        fskv.set("check", "check_OK")

        fskv.set("I_SCALE_ENABLE_CHX_CONFIG", {"1","1","1","1"})
        fskv.set("I_SCALE_NUM_CHX_CONFIG", {"40","40","40","40"})
        fskv.set("I_NUM_CHX_CONFIG", {"20","20","20","20"})
        fskv.set("V_NUM_CHX_CONFIG", {"250","250","250","250"})
        fskv.set("IV_NUM_ENABLE_CHX_CONFIG", {"1","1","1","1"})
        fskv.set("ZXTO_ENABLE_CHX_CONFIG", {"1","1","1","1"})
        fskv.set("VVVF_ENABLE_CHX_CONFIG", {"0","0","0","0"})
        fskv.set("TEMPERATURE_NUM_CONFIG", "80.00")
        fskv.set("START_Time_CHX_CONFIG", {"0","0","0","0"})
        fskv.set("CLOSE_Time_CHX_CONFIG", {"0","0","0","0"})
        fskv.set("Time_ENABLE_CHX_CONFIG", {"0","0","0","0"})
        fskv.set("POWER_CLOSE_ENABLE_CONFIG", "1")
        fskv.set("ElE_CHX", {"0","0","0","0"})
        fskv.set("LOCK_FLAG", "0")
        fskv.set("TimeSync_CONFIG", "")
        log.info("fskv------------init!")
    end
    log.info("Device_SN                 ------------",fskv.get("Device_SN"))
    log.info("I_SCALE_ENABLE_CHX_CONFIG ------------",fskv.get("I_SCALE_ENABLE_CHX_CONFIG")[1],fskv.get("I_SCALE_ENABLE_CHX_CONFIG")[2],fskv.get("I_SCALE_ENABLE_CHX_CONFIG")[3],fskv.get("I_SCALE_ENABLE_CHX_CONFIG")[4])
    log.info("I_SCALE_NUM_CHX_CONFIG    ------------",fskv.get("I_SCALE_NUM_CHX_CONFIG")[1],fskv.get("I_SCALE_NUM_CHX_CONFIG")[2],fskv.get("I_SCALE_NUM_CHX_CONFIG")[3],fskv.get("I_SCALE_NUM_CHX_CONFIG")[4])
    log.info("I_NUM_CHX_CONFIG          ------------",fskv.get("I_NUM_CHX_CONFIG")[1],fskv.get("I_NUM_CHX_CONFIG")[2],fskv.get("I_NUM_CHX_CONFIG")[3],fskv.get("I_NUM_CHX_CONFIG")[4])
    log.info("V_NUM_CHX_CONFIG          ------------",fskv.get("V_NUM_CHX_CONFIG")[1],fskv.get("V_NUM_CHX_CONFIG")[2],fskv.get("V_NUM_CHX_CONFIG")[3],fskv.get("V_NUM_CHX_CONFIG")[4])
    log.info("IV_NUM_ENABLE_CHX_CONFIG  ------------",fskv.get("IV_NUM_ENABLE_CHX_CONFIG")[1],fskv.get("IV_NUM_ENABLE_CHX_CONFIG")[2],fskv.get("IV_NUM_ENABLE_CHX_CONFIG")[3],fskv.get("IV_NUM_ENABLE_CHX_CONFIG")[4])
    log.info("ZXTO_ENABLE_CHX_CONFIG    ------------",fskv.get("ZXTO_ENABLE_CHX_CONFIG")[1],fskv.get("ZXTO_ENABLE_CHX_CONFIG")[2],fskv.get("ZXTO_ENABLE_CHX_CONFIG")[3],fskv.get("ZXTO_ENABLE_CHX_CONFIG")[4])
    log.info("VVVF_ENABLE_CHX_CONFIG    ------------",fskv.get("VVVF_ENABLE_CHX_CONFIG")[1],fskv.get("VVVF_ENABLE_CHX_CONFIG")[2],fskv.get("VVVF_ENABLE_CHX_CONFIG")[3],fskv.get("VVVF_ENABLE_CHX_CONFIG")[4])
    log.info("TEMPERATURE_NUM_CONFIG    ------------",fskv.get("TEMPERATURE_NUM_CONFIG"))
    log.info("START_Time_CHX_CONFIG     ------------",fskv.get("START_Time_CHX_CONFIG")[1],fskv.get("START_Time_CHX_CONFIG")[2],fskv.get("START_Time_CHX_CONFIG")[3],fskv.get("START_Time_CHX_CONFIG")[4])
    log.info("CLOSE_Time_CHX_CONFIG     ------------",fskv.get("CLOSE_Time_CHX_CONFIG")[1],fskv.get("CLOSE_Time_CHX_CONFIG")[2],fskv.get("CLOSE_Time_CHX_CONFIG")[3],fskv.get("CLOSE_Time_CHX_CONFIG")[4])
    log.info("Time_ENABLE_CHX_CONFIG    ------------",fskv.get("Time_ENABLE_CHX_CONFIG")[1],fskv.get("Time_ENABLE_CHX_CONFIG")[2],fskv.get("Time_ENABLE_CHX_CONFIG")[3],fskv.get("Time_ENABLE_CHX_CONFIG")[4])
    log.info("POWER_CLOSE_ENABLE_CONFIG ------------",fskv.get("POWER_CLOSE_ENABLE_CONFIG"))
    log.info("ElE_CHX                   ------------",fskv.get("ElE_CHX")[1],fskv.get("ElE_CHX")[2],fskv.get("ElE_CHX")[3],fskv.get("ElE_CHX")[4])
    log.info("LOCK_FLAG                 ------------",fskv.get("LOCK_FLAG"))
    log.info("TimeSync_CONFIG           ------------",fskv.get("TimeSync_CONFIG"))
end)


log.info("shell -- file -- _init -- end")
