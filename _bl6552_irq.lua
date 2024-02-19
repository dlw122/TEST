log.info("shell -- file -- _bl6552_irq -- start")

--配置gpio7为输入模式，下拉，并会触发中断
--请根据实际需求更改gpio编号和上下拉
local INTX = {23,5,12,4}


local int_timer = 20

local BL6552_IRQ_EVENT = "Prof_IV" -- 事件

local function bl6552_irq_init(Event,Chx)
    gpio.debounce(INTX[Chx], int_timer)
    gpio.setup(INTX[Chx], function()
        log.info("INT Chx:",Chx,"  -  GPIO:", INTX[Chx])
        _bl6552_data.BL6552_Chx(Event,Chx,"0","0") -- 插入中断事件BL6552_Chx(Event,Chx,Data,Tag)
    end, gpio.PULLUP)
end

bl6552_irq_init(BL6552_IRQ_EVENT,1)
bl6552_irq_init(BL6552_IRQ_EVENT,2)
bl6552_irq_init(BL6552_IRQ_EVENT,3)
bl6552_irq_init(BL6552_IRQ_EVENT,4)

log.info("shell -- file -- _bl6552_irqs -- end")
