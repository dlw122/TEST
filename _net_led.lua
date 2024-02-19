log.info("shell -- file -- _net_led -- start")

--LED引脚判断赋值结束

local LEDA= gpio.setup(27, 0, gpio.PULLUP)

---------------------------------------------------
-- 自检灯状态刷新
---------------------------------------------------
sys.taskInit(function()
    while true do
        sys.wait(100)
    end
end)

sys.taskInit(function()
    --流水灯程序
    sys.wait(5000) --延时5秒等待网络注册
    log.info("mobile.status()", mobile.status())
    while true do
        if mobile.status() == 1 then
            sys.wait(600)
            netLed.setupBreateLed(LEDA)
        else
            sys.wait(3000)
            log.info("net fail")
        end
    end
end)

log.info("shell -- file -- _net_led -- end")
