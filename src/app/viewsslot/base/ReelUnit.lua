

--
-- Author: 	刘阳
-- Date: 	2019-04-30
-- Desc:	单个滚轴

local SymbolUnit = require("app.base.ReelBase.SymbolUnit")
local ReelUnit = class("ReelUnit",cc.Node)


-- 运动状态 --
ReelUnit.RollStatus = 
{
	RollStatus_Idle  		= 0,	-- 静止状态  --
	RollStatus_Roll 		= 1,	-- 滚动状态	--
}


--[[
	param的参数结构 = {
		width = 10,
		heigth = 10,
		view_count = 1,
		speed = 1,
	}
]]
function ReelUnit:ctor( reelConfig,reelIndex )
	assert( reelConfig," !! reelConfig is nil  !! " )
	self._reelConfig 		= reelConfig
	self._symbolIdPointer 	= 1    																-- 当前数据的索引 (位置最低的那个symbol)
	self._symbolList 		= {}   																-- 存放信号块列表
	self._symbolData        = reelConfig["roll_list"..reelIndex]								-- reel的数据源
	self._symbolSize 		= cc.size( reelConfig.symbol_width,reelConfig.symbol_height )		-- 单个单元格的大小	
	self._curSpeed 			= 0	   																-- 当前速度	
	self._maxSpeed          = param.speed 														-- 最大速度
	self._topSymbolUnit		= nil  																-- 处于最高位置的信号块
	self._status 			= self.RollStatus.RollStatus_Idle									-- 初始状态

	-- 检查参数配置是否正确
	self:checkParam( reelConfig )
	-- 初始化参数
	self:initReelParam()
	-- 初始化裁剪区域
	self:addClipNode()
	-- 初始化信号块
	self:initSymbol()
end

-- ################################ 初始化相关 ################################
-- 检查参数是否正确
function ReelUnit:checkParam( param )
	local max_index = #param.size_type
	if param.size_type[max_index] > param.view_count then
		assert( false," !! 可是区域设置显示不下最大的信号块 !! " )
		return false
	end
	return true
end

-- 初始化滚轴 (这里面的参数有可能会改变 比如 增加可视区域) --
function ReelUnit:initReelParam()
	self._symbolViewCount  	= self._reelConfig.view_count													 		 -- 当前reel显示几个单元格
	self._symbolTotalCount 	= self._symbolViewCount + 2														 		 -- 需要创建的单元格
	self._size 			 	= cc.size( self._symbolSize.width,self._symbolSize.height * self._symbolViewCount ) 	 -- 裁剪区域的尺寸
	self._bottomPosY		= 0

	-- 设置数据指针(默认指向已经创建的数据位置)
	self._symbolIdPointer   = self._symbolTotalCount
end
-- 初始化裁剪区域
function ReelUnit:addClipNode()
	-- 添加裁剪node
	if self._clippingNode == nil then
		self._clippingNode = cc.ClippingRectangleNode:create()
		self:addChild( self._clippingNode )
	end
	self._clippingNode:setClippingRegion(cc.rect(0,0,self._size.width,self._size.height))

	-- TODO 添加背景layer 
	if self._bgLayer == nil then
		self._bgLayer = cc.LayerColor:create(cc.c4b(150,150,150,150))
  		self._clippingNode:addChild( self._bgLayer )
  	end
end
-- 添加信号块
function ReelUnit:initSymbol()
	-- 不存在
	if not self._clippingNode then
		return
	end
	-- 添加第一个symbol(设置位置)
	local height = self:getSymbolHeightById( self._symbolData[1] )
	local first_posy = self._bottomPosY - height
	self:createSymbolUnit( self._symbolData[1],first_posy )
	-- 添加第二个symbol(位置一定是0)
	self:createSymbolUnit( self._symbolData[2],self._bottomPosY )
	-- 添加第三个之后的位置
	for i = 3,self._symbolTotalCount do
		local posy = self:getPosYFromSecond( i )
		self:createSymbolUnit( self._symbolData[i],posy )
	end
end
--[[
	-- 创建单个Unit
	posY:在裁剪区的位置

]]
function ReelUnit:createSymbolUnit( symbolId,posY )
	assert( symbolId," !! symbolId is nil !! ")
	assert( posY," !! posY is nil !! " )
	local symbol = SymbolUnit.new()
	symbol:loadUIdata( symbolId )
	self._clippingNode:addChild( symbol )
	symbol:setPositionY( posY )
	table.insert( self._symbolList,symbol )
end
--[[
	计算当前的信号块在滚轴的裁剪区存放位置
	比如:要计算第三个信号块 需要得到第二个信号块的位置+第二个信号块的高度
]]
function ReelUnit:getPosYFromSecond( index )
	assert( index," !! index is nil !! " )
	assert( index > 2," !! index must be start 3 !! ")
	local height = 0
	for i = 2,index - 1 do
		height = height + self:getSymbolHeightById( self._symbolData[i] )
	end
	local posy = self._bottomPosY + height
	return posy
end
-- 根据信号源id获得当前Symbol尺寸
function ReelUnit:getSymbolHeightById( symbolId )
	assert( symbolId," !! symbolId is nil !! " )
	return self._reelConfig.size_type[symbolId] * self._symbolSize.height
end
-- 根据信号源id获得当前Symbol的size_type
function ReelUnit:getSymbolSizeTypeById( symbolId )
	assert( symbolId," !! symbolId is nil !! " )
	return self._reelConfig.size_type[symbolId]
end
-- ###########################################################################






function ReelUnit:updataSymbolUnit( dt )
	-- 设置位置
	for i,v in ipairs( self._symbolList ) do
		local posy = v:getPositionY()
		posy = posy - self._maxSpeed
		v:setPositionY( posy )
	end
	-- 重置数据指针
	for i,v in ipairs( self._symbolList ) do
		-- 当前symbol的最低位置
		local bottom_posy = self._bottomPosY - self:getSymbolHeightById( v:getNSymbolID() )
		local posy = v:getPositionY()
		if posy <= bottom_posy then
			-- 移动到最高位置
			local topY = self:getTopPosY()
			v:setPositionY( topY )
			-- 设置最高位置的信号块
			self._topSymbolUnit = v
			-- 重置数据指针
			self._symbolIdPointer = self._symbolIdPointer + 1
			if self._symbolIdPointer > #self._symbolData then
				self._symbolIdPointer = 1
			end
			-- 重置显示的数据
			v:loadUIdata( self._symbolData[self._symbolIdPointer] )
		end
	end
	-- 检查是否有停止滚动的命令
	if self._destUnitNode then
		if self._destUnitNode:getPositionY() <= 0 then
			-- 关闭定时器
			self:unscheduleUpdate()
			self._status = self.RollStatus.RollStatus_Idle
			self._destUnitNode = nil
		end
	end
end

-- 获取滚轴此时所有symbol最高位置的那个symbol
function ReelUnit:getTopPosY()
	local topY = 0
	local symbolId = 0
	for i,v in ipairs( self._symbolList ) do
		if v:getPositionY() > topY then
			topY = v:getPositionY()
			symbolId = v:getNSymbolID()
		end
	end
	topY = topY + self:getSymbolHeightById( symbolId )
	return topY
end









-- ################################ 外部接口调用 ################################
-- 开启滚动
function ReelUnit:startRoll()
	if self._status == self.RollStatus.RollStatus_Roll then
		cclog("liuyang 状态为滚动 不能滚动")
		return
	end
	-- 设置状态
	self._status = self.RollStatus.RollStatus_Roll
	-- 开启帧调用
	self:onUpdate( function( dt ) 
		-- 更新信号块位置 --
		self:updataSymbolUnit(dt)
	end)	
end
-- 停止滚动
function ReelUnit:stopRoll( destData )
	if not destData then
		assert( false,"liuyang 数据格式错误:需要的数据个数为: 没有传入数据")
		return
	end
	if #destData ~= self._symbolViewCount then
		assert( false,"liuyang 数据格式错误:需要的数据个数为:"..self._symbolViewCount.." 当前传入的数据为:"..(#destData))
		return
	end

	-- 需要变换数据 得到需要更改的索引位置
	local newDestData = self:calDestData( destData )

	dump( newDestData,"------------> newDestData = " )

	-- 更换数据
	local result = clone( self._symbolData )
	-- 算出要修改的数据的索引
	local change_index = {}
	for i,v in ipairs( newDestData ) do
		local index = self._symbolIdPointer + (i - 1)
		if index > #self._symbolData then
			index = self._symbolIdPointer + (i - 1) - #self._symbolData
		end
		table.insert( change_index,index )
	end
	for i,v in ipairs( newDestData ) do
		result[change_index[i]] = v
	end
	-- 更换显示数据
	self._orgSymbolData = clone( self._symbolData )
	self._symbolData = result

	-- 设置停止滚动的指令
	self._destUnitNode = self._topSymbolUnit
	self._destUnitNode:loadUIdata( result[change_index[1]] )
end
-- ###########################################################################

-- 解析目标数据
function ReelUnit:calDestData( destData )
	local newData = {}
	-- 检查数据格式是否正确
	local result = {}
	local hasSymbolIdByData = function( source,symbolId )
		for i,v in ipairs( source ) do
			if v.symbolId == symbolId then
				return true, i
			end
		end
		return false,0
	end

	for i,symbolId in ipairs( destData ) do
		local has,index = hasSymbolIdByData( result,symbolId )
		if not has then
			local meta = { 
				symbolId = symbolId,
				count = 1,
				size_type = self:getSymbolSizeTypeById( symbolId ) 
			}
			table.insert( result,meta )
		else
			result[index].count = result[index].count + 1
		end
	end

	dump( result,"-------------> result " )

	-- 1:检查数据格式
	local total_size = 0
	for i,v in ipairs( result ) do
		total_size = total_size + v.count
		if v.count ~= v.size_type then
			return
		end
	end
	-- 2:检查数据格式
	if total_size ~= self._symbolViewCount then
		return
	end

	for i,v in ipairs( result ) do
		table.insert( newData,v.symbolId )
	end
	return newData
end


return ReelUnit

