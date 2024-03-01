log.info("shell -- file --_power_irq -- start")
--配置gpio7为输入模式，下拉，并会触发中断
--请根据实际需求更改gpio编号和上下拉
local KEY_POWER =24

local power_irq_timer = 50

gpio.debounce(KEY_POWER, power_irq_timer,1)
gpio.setup(KEY_POWER, function()
    log.info("KEY_POWER - ", KEY_POWER)
    if fskv.get("POWER_CLOSE_ENABLE_CONFIG") == "1" then
        sys.publish("DeviceWarn_Status","Alert_PowerLost", 0, "", "", "")
    end
    
end, gpio.PULLDOWN,gpio.FALLING)

log.info("shell -- file -- _power_irq -- end")
