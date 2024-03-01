log.info("shell -- file -- key_irq -- start")

--local _mqtt_send      = require("_mqtt_send")
--配置gpio7为输入模式，下拉，并会触发中断
--请根据实际需求更改gpio编号和上下拉
local KEYX = {17,19,18,2,16}

local key_timer = 50
local key_irq = "KeyOP"

-- 自检锁按下3S计时开始标志
local lock_start_time = 0

-- 自检锁按下后    0-未锁   1-加锁
local lock_enable_flag = 0
local function Get_lock_enable_flag() 
    return lock_enable_flag 
end

local Self_Check = 0
-- 联网状态标识
local function Set_Self_Check(DATA) Self_Check = DATA end
local function Get_Self_Check() return Self_Check end

------------------------------------------------------
gpio.setup(KEYX[1] , nil)  --输入模式
------------------------------------------------------

gpio.debounce(KEYX[2], key_timer, 1)
gpio.setup(KEYX[2], function()
    log.debug(" -------------------------------", KEYX[2])
    if _led.Get_Electromagnetic_ChX(1) == 1 then 
        sys.publish("LED_Chx",key_irq,1,0)
    elseif _led.Get_Electromagnetic_ChX(1) == 0 then
        sys.publish("LED_Chx",key_irq,1,1)
    end
end, gpio.PULLUP,gpio.FALLING,4)

gpio.debounce(KEYX[3], key_timer, 1)
gpio.setup(KEYX[3], function()
    log.debug(" -------------------------------", KEYX[3])
    if _led.Get_Electromagnetic_ChX(2) == 1 then 
        sys.publish("LED_Chx",key_irq,2,0)
    elseif _led.Get_Electromagnetic_ChX(2) == 0 then
        sys.publish("LED_Chx",key_irq,2,1)
    end
end, gpio.PULLUP,gpio.FALLING,4)

gpio.debounce(KEYX[4], key_timer, 1)
gpio.setup(KEYX[4], function()
    log.debug(" -------------------------------", KEYX[4])
    if _led.Get_Electromagnetic_ChX(3) == 1 then 
        sys.publish("LED_Chx",key_irq,3,0)
    elseif _led.Get_Electromagnetic_ChX(3) == 0 then
        sys.publish("LED_Chx",key_irq,3,1)
    end
end, gpio.PULLUP,gpio.FALLING)

gpio.debounce(KEYX[5], key_timer, 1)
gpio.setup(KEYX[5], function()
    log.debug(" -------------------------------", KEYX[5])
    if _led.Get_Electromagnetic_ChX(4) == 1 then 
        sys.publish("LED_Chx",key_irq,4,0)
    elseif _led.Get_Electromagnetic_ChX(4) == 0 then
        sys.publish("LED_Chx",key_irq,4,1)
    end
end, gpio.PULLUP,gpio.FALLING)

-- 处理自检按键
sys.taskInit(function()
    local lock_num = 0
    local Self = 0

    while true do
        -- 自检按键按下后
        if 1 == gpio.get(KEYX[1]) then
            lock_num = 0
        elseif 0 == gpio.get(KEYX[1]) then
            lock_num = lock_num + 1
            if (lock_num > 30) then
                lock_num = 0
                if (lock_enable_flag == 0) then
                    lock_enable_flag = 1
                    fskv.set("LOCK_FLAG", tostring(lock_enable_flag))
                    Self = Self_Check -- 保存自检灯状态
                    Self_Check = 0 -- 自检灯常亮
                    -- 关闭所有电磁阀、灯
                    
                    _led.LED_Chx("Lock",1,0)
                    _led.LED_Chx("Lock",2,0)
                    _led.LED_Chx("Lock",3,0)
                    _led.LED_Chx("Lock",4,0)
                    sys.publish("DeviceWarn_Status","Lock", 0, "1", "", "")
                    log.debug("锁上--------------")
                elseif (lock_enable_flag == 1) then -- 处于加锁状态
                    lock_enable_flag = 0 -- 未锁
                    fskv.set("LOCK_FLAG", tostring(lock_enable_flag)) -- 与按键状态不一样，这个时在开机10S使用，按键保存时5S，放在一起会导致未使用就保存初始值
                    Self_Check = Self -- 还原自检灯加锁前状态

                    _led.LED_Chx("Lock",1,0)
                    _led.LED_Chx("Lock",2,0)
                    _led.LED_Chx("Lock",3,0)
                    _led.LED_Chx("Lock",4,0)
                    sys.publish("DeviceWarn_Status","Lock", 0, "0", "", "")
                    log.debug("解锁--------------")
                end
            end
        end
        sys.wait(100)
    end
end)

---------------------------------------------------
-- 开机还原关机保留的电磁阀状态
---------------------------------------------------
local function SYS_START_SET_Electromagnetic_Chx()
    --刚开机时设置系统为锁定状态
    --不需要把锁定状态上报给服务器，因为此时未联网，不需要上报
    lock_enable_flag = tonumber(fskv.get("LOCK_FLAG"))
    sys.wait(10000)
    for i = 1,4,1 do
        local r = crypto.trng(4)
        local _, ir = pack.unpack(r, "I")
        log.debug("延时",(ir%2500))
        sys.wait((ir%2500))
        sys.publish("LED_Chx","SysOP",i,tonumber(fskv.get("ElE_CHX")["_" .. tostring(i)]))
    end
end

sys.taskInit(SYS_START_SET_Electromagnetic_Chx)

log.info("shell -- file -- key_irq -- end")
-- 用户代码已结束---------------------------------------------
------供外部文件调用的函数
return {
    Get_lock_enable_flag = Get_lock_enable_flag,
    Set_Self_Check       = Set_Self_Check,
    Get_Self_Check       = Get_Self_Check,
}
--
