
local NodePoker = import(".NodePoker")

local GamePlay  = class("GamePlay",BaseLayer)

local STAGE_ICON = {
	[1]  = "image/play/Groupstage1.png",
	[2]  = "image/play/Groupstage2.png",
	[3]  = "image/play/Groupstage3.png",
	[4]  = "image/pay/Quarterfinal.png",
	[5]  = "image/pay/SemiFinals.png",
	[6]  = "image/pay/Final.png"
}

function GamePlay:ctor( param )
    assert( param," !! param is nil !! ")
    assert( param.name," !! param.name is nil !! ")
    GamePlay.super.ctor( self,param.name )
    self:addCsb( "csbzuqiu/Play.csb" )

    -- pass 
    self:addNodeClick( self.ButtonPass,{ 
        endCallBack = function() self:clickPass() end,
    })

    -- 隐藏定位的poker
    self._playerPokerPos = {}
    self._aiPokerPos = {}
    for i = 1,6 do
    	self["PlayerPoker"..i]:setVisible( false )
    	self["AIPoker"..i]:setVisible( false )
    	table.insert( self._playerPokerPos,cc.p( self["PlayerPoker"..i]:getPosition() ) )
    	table.insert( self._aiPokerPos,cc.p( self["AIPoker"..i]:getPosition() ) )
    end

    self.ImageOutAI:setVisible( false )
    self.ImageOutPlayer:setVisible( false )
    self:hideOpIcon()
    self.ButtonPass:setVisible( false )

    self._outAIPos = cc.p( self.ImageOutAI:getPosition() )
    self._outPlayerPos = cc.p( self.ImageOutPlayer:getPosition() )

    self._playerPokerAngle = { -19,-14,-5,5,14,19 }
    self._aiPokerAngle = { 19,14,5,-5,-14,-19 }
    self._countryIndex = param.data.country_index
    self._stage = 1
    if param.data.stage then
    	self._stage = param.data.stage
    end

    self._aiPaiDuiCards = {}
    self._playerPaiDuiCards = {}

    self._aiHandCards = {}
    self._playerHandCards = {}

    self._aiOutCards = {}
    self._playerOutCards = {}
    -- 玩家能否点击牌的标志
    self._playerCanTouch = false
end

function GamePlay:onEnter()
	GamePlay.super.onEnter( self )
    casecadeFadeInNode( self._csbNode,0.5 )
    -- 初始化数据
    self:loadDataUI()
    -- 创建 bei poker
    self:createBeiPoker()
    -- 开始发牌
    performWithDelay( self,function()
    	self:sendCardBeganAction()
    end, 0.2)
end

function GamePlay:loadDataUI()
	-- 玩家国家
	self.ImageCountry1:loadTexture( country_config.europe[self._countryIndex].icon,1 )
	-- ai随机国家
	local ai_country_index = country_config.getAiRandomCountry( self._countryIndex ) 
	self.ImageCountry2:loadTexture( country_config.europe[ai_country_index].icon,1 )
	-- 第几场
	self.ImageStage:loadTexture( STAGE_ICON[self._stage] )
end

function GamePlay:createBeiPoker()
	local ai_poker,player_poker = zuqiu_card_config.getRandomPokerByBegan( self._stage )
	-- ai
	local panel_size = self.ImageBeiAI:getContentSize()
	local pos = cc.p( panel_size.width / 2,panel_size.height / 2 + 7 )
	for i,v in ipairs( ai_poker ) do
		local poker = NodePoker.new( self,v )
		self.ImageBeiAI:addChild( poker )
		table.insert( self._aiPaiDuiCards,poker )
		poker:setPosition( cc.p( pos.x - i * 1,pos.y + i * 1 ) )
		poker:setLocalZOrder( i )
		poker._image:getVirtualRenderer():getSprite():setFlippedY( true )
	end
	-- player
	for i,v in ipairs( player_poker ) do
		local poker = NodePoker.new( self,v )
		self.ImageBeiPlayer:addChild( poker )
		table.insert( self._playerPaiDuiCards,poker )
		poker:setPosition( cc.p( pos.x - i * 1,pos.y + i * 1 ) )
		poker:setLocalZOrder( i )
	end
end

function GamePlay:sendCardBeganAction()
	-- player的数据
	local send_player = {}
	for i = 1,6 do
		local index = #self._playerPaiDuiCards - i + 1
		local poker = self._playerPaiDuiCards[index]
		table.insert( send_player,poker:getNumIndex() )
	end
	-- 排序
	table.sort( send_player, function( a,b )
		return a > b
	end )

	-- ai的数据
	local send_ai = {}
	for i = 1,6 do
		local index = #self._aiPaiDuiCards - i + 1
		local poker = self._aiPaiDuiCards[index]
		table.insert( send_ai,poker:getNumIndex() )
	end
	-- 排序
	table.sort( send_ai, function( a,b ) 
		return a < b
	end )

	-- 先发player
	local actions = {}
	local action_time = 0.5
	for i = 1,6 do
		local delay = cc.DelayTime:create( 0.3 )
		local call_player_mo = cc.CallFunc:create( function()
			self:playerMoCard( send_player[i],7 - i,action_time )
		end )
		table.insert( actions,delay )
		table.insert( actions,call_player_mo )
	end
	-- 再发ai
	for i = 1,6 do
		local delay = cc.DelayTime:create( 0.3 )
		local call_ai_mo = cc.CallFunc:create( function()
			self:aiMoCard( send_ai[i],7 - i,action_time )
		end )
		table.insert( actions,delay )
		table.insert( actions,call_ai_mo )
	end
	-- ai 优先出牌
	local delay1 = cc.DelayTime:create( 0.3 )
	table.insert( actions,delay1 )
	local call_ai_out = cc.CallFunc:create( function()
		self:loadPlayerOpIcon()
		self:aiOutCard()
	end )
	table.insert( actions,call_ai_out )
	self:runAction( cc.Sequence:create( actions ) )
end

-- 玩家摸牌
function GamePlay:playerMoCard( numIndex,seatPos,actionTime )
	assert( numIndex," !! numIndex is nil !! " )
	assert( seatPos," !! seatPos is nil !! " )
	assert( actionTime," !! actionTime is nil !! " )
	assert( #self._playerPaiDuiCards > 0, " !! player pai dui not has card !! " )

	-- 移除顶部poker
	local poker = self._playerPaiDuiCards[#self._playerPaiDuiCards]
	self._playerPaiDuiCards[#self._playerPaiDuiCards] = nil
	poker:removeFromParent()

	print("---------------> 玩家牌堆还有牌的数量是:"..#self._playerPaiDuiCards)

	-- 创建poker到手牌
	local pos = cc.p( self.ImageBeiPlayer:getPosition() )
	local dest_pos = cc.p( self["PlayerPoker"..seatPos]:getPosition() )
	local new_poker = NodePoker.new( self,numIndex )
	self._csbNode:addChild( new_poker )
	new_poker:showPoker()
	new_poker:setSeatPos( seatPos )
	self._playerHandCards[#self._playerHandCards + 1] = new_poker
	new_poker:setPosition( pos )
	local move_to = cc.MoveTo:create( actionTime,dest_pos )
	local rotate_to = cc.RotateTo:create( actionTime,self._playerPokerAngle[seatPos] )
	local spawn = cc.Spawn:create( { move_to,rotate_to } )
	local call_addClick = cc.CallFunc:create( function()
		new_poker:addPokerClick()
	end )

	new_poker:runAction( cc.Sequence:create({ spawn,call_addClick }) )
end

-- ai摸牌
function GamePlay:aiMoCard( numIndex,seatPos,actionTime )
	assert( numIndex," !! numIndex is nil !! " )
	assert( seatPos," !! seatPos is nil !! " )
	assert( actionTime," !! actionTime is nil !! " )
	assert( #self._aiPaiDuiCards > 0, " !! ai pai dui not has card !! " )

	-- 移除顶部poker
	local poker = self._aiPaiDuiCards[#self._aiPaiDuiCards]
	self._aiPaiDuiCards[#self._aiPaiDuiCards] = nil
	poker:removeFromParent()

	print("---------------> ai牌堆还有牌的数量是:"..#self._aiPaiDuiCards)

	-- 创建poker到手牌
	local pos = cc.p( self.ImageBeiAI:getPosition() )
	local dest_pos = cc.p( self["AIPoker"..seatPos]:getPosition() )
	local new_poker = NodePoker.new( self,numIndex )
	self._csbNode:addChild( new_poker )
	new_poker._image:getVirtualRenderer():getSprite():setFlippedY( true )
	new_poker:showPoker()
	new_poker:setSeatPos( seatPos )
	self._aiHandCards[#self._aiHandCards + 1] = new_poker
	new_poker:setPosition( pos )
	local move_to = cc.MoveTo:create( actionTime,dest_pos )
	local rotate_to = cc.RotateTo:create( actionTime,self._aiPokerAngle[seatPos] )
	local spawn = cc.Spawn:create( { move_to,rotate_to } )
	new_poker:runAction( spawn )
end

-- ai出牌逻辑
function GamePlay:aiOutCard()
	local out_poker = nil

	-- 是否选择花色最多的
	local select_most_huase = true
	if #self._aiOutCards > 0 then
		local top_poker = self._aiOutCards[#self._aiOutCards]
		if top_poker:isShowBei() == false then
			select_most_huase = false
		end
	end

	if select_most_huase then
		-- 1: 桌面上没有牌 选择花色最多的牌出
		local hua_se = {}
		for i,v in ipairs( self._aiHandCards ) do
			local color = zuqiu_card_config[v:getNumIndex()].color
			if not hua_se[color] then
				hua_se[color] = 1
			else
				hua_se[color] = hua_se[color] + 1
			end
		end
		local max_count,max_color = 0,0
		for k,v in pairs( hua_se ) do
			if v > max_count then
				max_count = v
				max_color = k
			end
		end
		-- 在花色中选择点数最大的
		local max_card_num = 0
		for i,v in ipairs( self._aiHandCards ) do
			local color = zuqiu_card_config[v:getNumIndex()].color
			if color == max_color then
				if v:getCardNum() > max_card_num then
					out_poker = v
					max_card_num = v:getCardNum()
				end
			end
		end
	else
		local top_poker = self._aiOutCards[#self._aiOutCards]
		local color = zuqiu_card_config[top_poker:getNumIndex()].color
		-- 选择相同花色
		local player_total_num = self:calPlayerOutTotalNum()
		local ai_total_num = self:calAiOutTotalNum()
		-- 1:优先寻找大于的
		for i,v in ipairs( self._aiHandCards ) do
			local v_color = zuqiu_card_config[v:getNumIndex()].color
			if v_color == color then
				if v:getCardNum() + ai_total_num > player_total_num then
					-- 出牌
					out_poker = v
					break
				end
			end
		end
		-- 2:寻找相等的
		if out_poker == nil then
			for i,v in ipairs( self._aiHandCards ) do
				local v_color = zuqiu_card_config[v:getNumIndex()].color
				if v_color == color then
					if v:getCardNum() + ai_total_num == player_total_num then
						-- 出牌
						out_poker = v
						break
					end
				end
			end
		end
	end

	if out_poker == nil then
		-- 没有牌可出 玩家赢牌
		self:excutePlayerWinPokerAction()
		return
	end

	local numIndex = out_poker:getNumIndex()
	local seat_pos = out_poker:getSeatPos()
	local start_pos = cc.p( out_poker:getPosition() )
	-- 移除手牌
	out_poker:removeFromParent()
	for i,v in ipairs( self._aiHandCards ) do
		if v == out_poker then
			table.remove( self._aiHandCards,i )
			break
		end
	end
	-- 出一张牌后 排序
	table.sort( self._aiHandCards,function( a,b )
		return a:getSeatPos() < b:getSeatPos() 
	end )

	-- 计算位置
	local move_count = 0
	for i,v in ipairs( self._aiOutCards ) do
		if not v:isShowBei() then
			move_count = move_count + 1
		end
	end
	local dest_pos = cc.p( self._outAIPos.x + move_count * 25,self._outAIPos.y - move_count * 20 )

	-- 创建牌 执行出牌动画
	local new_poker = NodePoker.new( self,numIndex )
	self._csbNode:addChild( new_poker )
	new_poker:setPosition( start_pos )
	new_poker:showPoker()
	self._aiOutCards[#self._aiOutCards + 1] = new_poker

	local move_to = cc.MoveTo:create( 0.5,dest_pos )
	local call_ai_mo = cc.CallFunc:create( function()
		if #self._aiPaiDuiCards > 0 then
			-- 有牌的情况下 移动牌
			local action_time = 0.5
			local num_index,insert_seatPos = self:aiMoveSortHandCard( seat_pos,action_time )
			-- 摸牌
			self:aiMoCard( num_index,insert_seatPos,action_time )
		else
			self:moveSortHandCardByPaiDuiNoCards( self._aiHandCards,0.5,self._aiPokerPos,self._aiPokerAngle )
		end
	end )
	local call_move_over = cc.CallFunc:create( function()
		-- 1:是否需要pmax
		local is_pmax = self:checkPMax()
		if is_pmax then
			-- 播放pax动画
			self:excutePMaxAction( 1 )
			return
		end
		-- 2:是否赢牌( 玩家不能出牌 且大于玩家的点数 就赢牌)
		if self:checkAIWinPoker() then
			-- 执行赢牌动画
			self:excuteAIWinPokerAction()
			return
		end
		-- 3:刷新玩家手牌的op icon 等待玩家出牌
		self:turnPlayerOutCard()
	end )
	new_poker:runAction( cc.Sequence:create({ move_to,call_ai_mo,call_move_over}) )
end

-- 轮到玩家出牌
function GamePlay:turnPlayerOutCard()
	self:loadPlayerOpIcon()
	self._playerCanTouch = true
	-- 显示pass按钮
	local has_out_card = false
	for i,v in ipairs( self._playerOutCards ) do
		if not v:isShowBei() then
			has_out_card = true
			break
		end
	end
	if has_out_card then
		self:showPass()
	end
end

-- 玩家点击出牌
function GamePlay:playerOutCard( poker )
	assert( poker," !! poker is nil !! " )
	if not self._playerCanTouch then
		return
	end

	local ai_total_num = self:calAiOutTotalNum()
	local player_total_num = self:calPlayerOutTotalNum()
	local poker_num = poker:getNumIndex()
	-- 不能出牌
	if player_total_num > 0 then
		local top_out_poker = self._playerOutCards[#self._playerOutCards]
		local out_color = zuqiu_card_config[top_out_poker:getNumIndex()].color
		local poker_color = zuqiu_card_config[poker:getNumIndex()].color
		-- 1:颜色不同 不能出牌
		if out_color ~= poker_color then
			return
		end
		-- -- 2:数量不足 不能出牌
		-- if ai_total_num > poker_num + player_total_num then
		-- 	return
		-- end
	end
	-- 出牌
	self._playerCanTouch = false
	self:hidePass()
	local numIndex = poker:getNumIndex()
	local seat_pos = poker:getSeatPos()
	local start_pos = cc.p( poker:getPosition() )
	-- 移除手牌
	poker:removeFromParent()
	for i,v in ipairs( self._playerHandCards ) do
		if v == poker then
			table.remove( self._playerHandCards,i )
			break
		end
	end
	-- 出一张牌后 排序
	table.sort( self._playerHandCards,function( a,b )
		return a:getSeatPos() < b:getSeatPos() 
	end )

	-- 计算位置
	local move_count = 0
	for i,v in ipairs( self._playerOutCards ) do
		if not v:isShowBei() then
			move_count = move_count + 1
		end
	end
	local dest_pos = cc.p( self._outPlayerPos.x + move_count * 25,self._outPlayerPos.y - move_count * 20 )

	-- 创建牌 执行出牌动画
	local new_poker = NodePoker.new( self,numIndex )
	self._csbNode:addChild( new_poker )
	new_poker:setPosition( start_pos )
	new_poker:showPoker()
	self._playerOutCards[#self._playerOutCards + 1] = new_poker

	local move_to = cc.MoveTo:create( 0.5,dest_pos )
	local call_player_mo = cc.CallFunc:create( function()
		if #self._playerPaiDuiCards > 0 then
			-- 有牌的情况下 移动牌
			local action_time = 0.5
			local num_index,insert_seatPos = self:playerMoveSortHandCard( seat_pos,action_time )
			-- 摸牌
			self:playerMoCard( num_index,insert_seatPos,action_time )

			performWithDelay( self,function()
				for i = 1,6 do
			    	if self._playerHandCards and self._playerHandCards[i] then
			    		self._playerHandCards[i]:setYinYingVisible( true )
			    	end
			    end
			end,action_time )
		else
			-- 没有牌的情况下移动牌
			self:moveSortHandCardByPaiDuiNoCards( self._playerHandCards,0.5,self._playerPokerPos,self._playerPokerAngle )
		end
	end )
	local delay = cc.DelayTime:create( 0.5 )
	local call_move_over = cc.CallFunc:create( function()
		self:hideOpIcon()
		-- 1:是否需要pmax
		local is_pmax = self:checkPMax()
		if is_pmax then
			-- 播放pax动画
			self:excutePMaxAction( 2 )
			return
		end
		-- 2:ai是否赢牌
		local ai_total_num = self:calAiOutTotalNum()
		local player_total_num = self:calPlayerOutTotalNum()
		if ai_total_num > player_total_num then
			self:excuteAIWinPokerAction()
			return
		end
		-- 3:自己是否赢牌( ao不能出牌 且大于ai的点数 就赢牌)
		if self:checkPlayerWinPoker() then
			-- 执行赢牌动画
			self:excutePlayerWinPokerAction()
			return
		end
		-- 4:通知ai出牌
		self:aiOutCard()
	end )
	local seq = cc.Sequence:create({ move_to,call_player_mo,delay,call_move_over })
	new_poker:runAction( seq )
end

-- 在牌堆有牌的情况下 ai排序手中牌
function GamePlay:aiMoveSortHandCard( outSeatPos,actionTime )
	return self:sortHandCards( self._aiPaiDuiCards,self._aiHandCards,outSeatPos,actionTime,self._aiPokerPos,self._aiPokerAngle,false )
end

-- 在牌堆有牌的情况下 palyer排序手中牌
function GamePlay:playerMoveSortHandCard( outSeatPos,actionTime )
	return self:sortHandCards( self._playerPaiDuiCards,self._playerHandCards,outSeatPos,actionTime,self._playerPokerPos,self._playerPokerAngle,true )
end

function GamePlay:sortHandCards( paiDuiCards,handCards,outSeatPos,actionTime,pokerPos,pokerAngle,isPlayer )
	assert( outSeatPos," !! outSeatPos is nil !! " )
	assert( actionTime," !! actionTime is nil !! " )
	assert( pokerPos," !! pokerPos is nil !! " )
	assert( pokerAngle," !! pokerAngle is nil !! " )
	assert( #paiDuiCards > 0," !! paiDuiCards nums must be > 0 !! " )
	-- 获得牌堆里面的牌
	local top_poker = paiDuiCards[#paiDuiCards]
	local top_numIndex = top_poker:getNumIndex()
	-- 计算新牌要插入的位置
	local insert_pos = 0
	if isPlayer then
		insert_pos = 6
		for i,v in ipairs( handCards ) do
			if top_numIndex <= v:getNumIndex() then
				insert_pos = i
				break
			end
		end
	else
		insert_pos = 6
		for i,v in ipairs( handCards ) do
			if top_numIndex >= v:getNumIndex() then
				insert_pos = i
				break
			end
		end
	end

	if insert_pos > outSeatPos then
		-- 向左移动 大于 outSeatPos 并且 小于等于 insert_pos 的牌进行移动
		for i,v in ipairs( handCards ) do
			local old_setPos = v:getSeatPos()
			if old_setPos > outSeatPos and old_setPos <= insert_pos then
				-- 左移动一位
				local new_setPos = old_setPos - 1
				v:setSeatPos( new_setPos )
				local new_pos = pokerPos[ new_setPos ]
				local move_to = cc.MoveTo:create( actionTime,new_pos )
				local rotate_to = cc.RotateTo:create( actionTime,pokerAngle[new_setPos] )
				local spawn = cc.Spawn:create({ move_to,rotate_to })
				v:runAction( spawn )
			end
		end
	elseif insert_pos == outSeatPos then
		-- 不需要移动
		insert_pos = outSeatPos
	else
		-- 向右移动 小于 outSeatPos 并且 大于等于 insert_pos 的牌进行移动
		for i,v in ipairs( handCards ) do
			local old_setPos = v:getSeatPos()
			if old_setPos < outSeatPos and old_setPos >= insert_pos then
				-- 左移动一位
				local new_setPos = old_setPos + 1
				v:setSeatPos( new_setPos )
				local new_pos = pokerPos[ new_setPos ]
				local move_to = cc.MoveTo:create( actionTime,new_pos )
				local rotate_to = cc.RotateTo:create( actionTime,pokerAngle[new_setPos] )
				local spawn = cc.Spawn:create({ move_to,rotate_to })
				v:runAction( spawn )
			end
		end
	end
	return top_numIndex,insert_pos
end

function GamePlay:moveSortHandCardByPaiDuiNoCards( source,actionTime,pokerPos,pokerAngle )
	assert( source," !! source is nil !! " )
	assert( actionTime," !! actionTime is nil !! " )
	assert( pokerPos," !! pokerPos is nil !! " )
	assert( pokerAngle," !! pokerAngle is nil !! " )
	if #source == 0 then
		return
	end
	local new_setPos = 0
	if #source == 1 or #source == 2 then
		-- 当剩一张牌的时候
		new_setPos = 3
	elseif #source == 3 then
		new_setPos = 2
	elseif #source == 4 or #source == 5 then
		new_setPos = 1
	end

	for i,v in ipairs( source ) do
		new_setPos = new_setPos + i - 1
		v:setSeatPos( new_setPos )
		local new_pos = pokerPos[ new_setPos ]
		local move_to = cc.MoveTo:create( actionTime,new_pos )
		local rotate_to = cc.RotateTo:create( actionTime,pokerAngle[new_setPos] )
		local spawn = cc.Spawn:create({ move_to,rotate_to })
		v:runAction( spawn )
	end
end

function GamePlay:checkPMax()
	if #self._aiOutCards == 0 then
		return false
	end
	if #self._playerOutCards == 0 then
		return false
	end
	-- 计算ai出牌的总和
	local ai_total_num = self:calAiOutTotalNum()
	-- 计算player出牌的总和
	local player_total_num = self:calPlayerOutTotalNum()
	if ai_total_num == player_total_num then
		return true
	end
	return false
end

--[[
	intType 1: ai先出牌 2:玩家先出牌
]]
function GamePlay:excutePMaxAction( intType )
	local pmax_img = ccui.ImageView:create( "image/play/pax.png",1 )
	self:addChild( pmax_img )
	pmax_img:setPosition( display.cx,display.cy )
	pmax_img:setScale( 2 )
	local scale_to = cc.ScaleTo:create( 0.5,1 )
	local delay = cc.DelayTime:create(1)
	local call_set = cc.CallFunc:create( function()
		-- 显示显示为背部
		for i,v in ipairs( self._aiOutCards ) do
			v:showBei()
			local move_to = cc.MoveTo:create( 0.2,self._outAIPos )
			v:runAction( move_to )
		end
		for i,v in ipairs( self._playerOutCards ) do
			v:showBei()
			local move_to = cc.MoveTo:create( 0.2,self._outPlayerPos )
			v:runAction( move_to )
		end
		-- 先发玩家 再发ai 每人发3张
		local ai_send_call = function()
			-- 1秒之后 牌聚拢
			local call_juji = function()
				performWithDelay( self,function()
					for i,v in ipairs( self._aiOutCards ) do
						local move_to = cc.MoveTo:create( 0.3,self._outAIPos )
						local call_bei = cc.CallFunc:create( function()
							v:showBei()
						end )
						v:runAction( cc.Sequence:create( { move_to,call_bei } ) )
					end
					for i,v in ipairs( self._playerOutCards ) do
						local move_to = cc.MoveTo:create( 0.3,self._outPlayerPos )
						local call_bei = cc.CallFunc:create( function()
							v:showBei()
						end )
						v:runAction( cc.Sequence:create( { move_to,call_bei } ) )
					end
					if intType == 1 then
						-- 0.5秒之后 ai出牌
						performWithDelay( self,function()
							self:aiOutCard()
						end,0.5 )
					else
						-- 等待玩家出牌
						performWithDelay( self,function()
							self:turnPlayerOutCard()
						end,0.5 )
					end
				end,1 )
			end
			self:createPokerToOut( self._aiPaiDuiCards,self._aiHandCards,self._aiOutCards,self._outAIPos,call_juji )
		end
		self:createPokerToOut( self._playerPaiDuiCards,self._playerHandCards,self._playerOutCards,self._outPlayerPos,ai_send_call )
	end )
	local remove = cc.RemoveSelf:create()
	pmax_img:runAction( cc.Sequence:create( { scale_to,delay,call_set,remove } ) )
end

function GamePlay:createPokerToOut( paiDuiCards,handCards,outCards,outPos,callBack )
	assert( paiDuiCards," !! paiDuiCards is nil !! ")
	assert( handCards," !! handCards is nil !! ")
	assert( outCards," !! outCards is nil !! ")
	assert( outPos," !! outPos is nil !! ")
	local paidui_count = #paiDuiCards
	local hands_count = #handCards
	assert( paidui_count + hands_count >= 3," !! error,this logic not exist !! " )
	local hands_need_out = 3 - paidui_count
	if hands_need_out > 0 then
		for i = 1,paidui_count do
			local poker = paiDuiCards[#paiDuiCards]
			paiDuiCards[#paiDuiCards] = nil
			local numIndex = poker:getNumIndex()
			local world_pos = poker:getParent():convertToWorldSpace( cc.p(poker:getPosition()) )
			local start_pos = self._csbNode:convertToNodeSpace( world_pos )
			poker:removeFromParent()

			if outPos == self._outPlayerPos then
				print("---------------> 玩家牌堆还有牌的数量是:"..#self._playerPaiDuiCards)
			else
				print("---------------> ai牌堆还有牌的数量是:"..#self._aiPaiDuiCards)
			end


			-- 创建牌 执行出牌动画
			local new_poker = NodePoker.new( self,numIndex )
			self._csbNode:addChild( new_poker )
			new_poker:setPosition( start_pos )
			new_poker:showPoker()
			outCards[#outCards + 1] = new_poker
			local dest_pos = cc.p( outPos.x + ( i - 1 ) * 35,outPos.y )
			local delay = cc.DelayTime:create( 0.1 * ( i - 1 ) )
			local move_to = cc.MoveTo:create( 0.3,dest_pos )
			local call_send = cc.CallFunc:create( function()
				if i == paidui_count then
					-- 从手牌中发牌
					for j = 1,hands_need_out do
						local hand_poker = handCards[j]
						handCards[j] = nil
						local hadNumIndex = hand_poker:getNumIndex()
						local hand_world_pos = hand_poker:getParent():convertToWorldSpace( cc.p(hand_poker:getPosition()) )
						local hand_start_pos = self._csbNode:convertToNodeSpace( hand_world_pos )
						hand_poker:removeFromParent()
						-- 创建牌 执行出牌动画
						local hand_new_poker = NodePoker.new( self,hadNumIndex )
						self._csbNode:addChild( hand_new_poker )
						hand_new_poker:setPosition( hand_start_pos )
						hand_new_poker:showPoker()
						outCards[#outCards + 1] = hand_new_poker

						local hand_dest_pos = cc.p( outPos.x + ( i - 1 + j ) * 35,outPos.y )
						local hand_delay = cc.DelayTime:create( 0.1 * ( i - 1 + j ) )
						local hand_move_to = cc.MoveTo:create( 0.3,hand_dest_pos )
						local call_hand_send = cc.CallFunc:create( function()
							if j == hands_need_out and callBack then
								callBack()
							end
						end )
						hand_new_poker:runAction( cc.Sequence:create( { hand_delay,hand_move_to,call_hand_send } ) )
					end
				end
			end )
			new_poker:runAction( cc.Sequence:create( { delay,move_to,call_send } ) )
		end
	else
		-- 全部从牌堆发牌
		for i = 1,3 do
			local poker = paiDuiCards[#paiDuiCards]
			paiDuiCards[#paiDuiCards] = nil
			local numIndex = poker:getNumIndex()
			local world_pos = poker:getParent():convertToWorldSpace( cc.p(poker:getPosition()) )
			local start_pos = self._csbNode:convertToNodeSpace( world_pos )
			poker:removeFromParent()

			if outPos == self._outPlayerPos then
				print("---------------> 玩家牌堆还有牌的数量是:"..#self._playerPaiDuiCards)
			else
				print("---------------> ai牌堆还有牌的数量是:"..#self._aiPaiDuiCards)
			end

			-- 创建牌 执行出牌动画
			local new_poker = NodePoker.new( self,numIndex )
			self._csbNode:addChild( new_poker )
			new_poker:setPosition( start_pos )
			new_poker:showPoker()
			outCards[#outCards + 1] = new_poker
			local dest_pos = cc.p( outPos.x + ( i - 1 ) * 35,outPos.y )

			local delay = cc.DelayTime:create( 0.1 * ( i - 1 ) )
			local move_to = cc.MoveTo:create( 0.3,dest_pos )
			local call_send = cc.CallFunc:create( function()
				if i == 3 and callBack then
					callBack()
				end
			end )
			new_poker:runAction( cc.Sequence:create( { delay,move_to,call_send } ) )
		end
	end
end

function GamePlay:loadPlayerOpIcon()
	self:hideOpIcon()
	-- 设置belong
	for i = 1,5 do
		self:showBeLongIcon( i )
	end
	-- 设置Pmax
	local ai_total_num = self:calAiOutTotalNum()
	if ai_total_num > 0 then
		local player_total_num = self:calPlayerOutTotalNum()

		local top_out_poker = self._playerOutCards[#self._playerOutCards]
		local out_color = nil
		if top_out_poker then
			out_color = zuqiu_card_config[top_out_poker:getNumIndex()].color
		end

		for i = 1,6 do
			local poker = self._playerHandCards[i]
			if poker then
				local player_num = zuqiu_card_config[poker:getNumIndex()].num
				if out_color then
					local player_color = zuqiu_card_config[poker:getNumIndex()].color
					if out_color == player_color and ai_total_num == player_num + player_total_num then
						self["ImagePMax"..poker:getSeatPos()]:setVisible( true )
					end
				else
					if ai_total_num == player_num + player_total_num then
						self["ImagePMax"..poker:getSeatPos()]:setVisible( true )
					end
				end
			end
		end
	end
	-- 重置阴影
	for i = 1,6 do
		if self._playerHandCards[i] then
			self._playerHandCards[i]:setYinYingVisible( false )
		end
	end
	-- 设置canout
	if ai_total_num > 0 then
		local player_total_num = self:calPlayerOutTotalNum()

		local top_out_poker = self._playerOutCards[#self._playerOutCards]
		local out_color = nil
		if top_out_poker and not top_out_poker:isShowBei() then
			out_color = zuqiu_card_config[top_out_poker:getNumIndex()].color
		end

		for i = 1,6 do
			if self._playerHandCards[i] then
				local player_color = zuqiu_card_config[self._playerHandCards[i]:getNumIndex()].color
				if out_color then
					if player_color == out_color then
						local player_num = zuqiu_card_config[self._playerHandCards[i]:getNumIndex()].num
						if ai_total_num < player_num + player_total_num then
							local seat_pos = self._playerHandCards[i]:getSeatPos()
							self["ImageCanOut"..seat_pos]:setVisible( true )
						elseif ai_total_num > player_num + player_total_num then
							-- if player_total_num > 0 then
							-- 	self._playerHandCards[i]:setYinYingVisible( true )
							-- end
						end
					else
						self._playerHandCards[i]:setYinYingVisible( true )
					end
				end
			end
		end
	end
end

-- 计算ai出牌的总和
function GamePlay:calAiOutTotalNum()
	local ai_total_num = 0
	for i,v in ipairs( self._aiOutCards ) do
		if v:isShowBei() == false then
			ai_total_num = ai_total_num + zuqiu_card_config[v:getNumIndex()].num
		end
	end
	return ai_total_num
end

-- 计算玩家出牌的总和
function GamePlay:calPlayerOutTotalNum()
	local player_total_num = 0
	for i,v in ipairs( self._playerOutCards ) do
		if v:isShowBei() == false then
			player_total_num = player_total_num + zuqiu_card_config[v:getNumIndex()].num
		end
	end
	return player_total_num
end

function GamePlay:showBeLongIcon( pos )
	assert( pos," !! pos is nil !! " )
	local cur_poker = nil
	local next_poker = nil

	for i,v in ipairs( self._playerHandCards ) do
		local seat_pos = v:getSeatPos()
		if pos == seat_pos then
			cur_poker = v
		end
		if pos + 1 == seat_pos then
			next_poker = v
		end
	end

	if cur_poker and next_poker then
		local color1 = zuqiu_card_config[cur_poker:getNumIndex()].color
		local color2 = zuqiu_card_config[next_poker:getNumIndex()].color
		if color1 == color2 then
			self["ImageLong"..pos]:setVisible( true )
			self["ImageLong"..pos]:loadTexture( "image/play/Bringalong"..color1..".png",1 )
		end
	end
end

function GamePlay:hideOpIcon()
	for i = 1,6 do
    	if i < 6 then
    		self["ImageLong"..i]:setVisible( false )
    	end
    	self["ImagePMax"..i]:setVisible( false )
    	self["ImageCanOut"..i]:setVisible( false )
    end
end

function GamePlay:checkAIWinPoker()
	if #self._playerOutCards > 0 then
		local player_total_num = self:calPlayerOutTotalNum()

		if player_total_num == 0 then
			return false
		end

		local ai_total_num = self:calAiOutTotalNum()
		local player_out_poker = self._playerOutCards[#self._playerOutCards]
		local player_out_color = zuqiu_card_config[player_out_poker:getNumIndex()].color
		for i,v in ipairs( self._playerHandCards ) do
			local color = zuqiu_card_config[v:getNumIndex()].color
			if color == player_out_color then
				-- if v:getCardNum() + player_total_num >= ai_total_num then
				-- 	return false
				-- end
				return false
			end
		end
		return true
	end
	return false
end

function GamePlay:checkPlayerWinPoker()
	if #self._aiOutCards > 0 then
		local player_total_num = self:calPlayerOutTotalNum()
		local ai_total_num = self:calAiOutTotalNum()

		if ai_total_num == 0 then
			return false
		end

		local ai_out_poker = self._aiOutCards[#self._aiOutCards]
		local ai_out_color = zuqiu_card_config[ai_out_poker:getNumIndex()].color
		for i,v in ipairs( self._aiHandCards ) do
			local color = zuqiu_card_config[v:getNumIndex()].color
			if color == ai_out_color then
				if v:getCardNum() + ai_total_num >= player_total_num then
					return false
				end
			end
		end
		return true
	end
	return false
end

function GamePlay:excuteAIWinPokerAction()
	local call_move_player = function()
		local call_ai_out = function()
			-- ai出牌
			-- 检查ai是否赢得游戏
			if #self._playerPaiDuiCards <= 1 then
				self:isGameOver(1)
			else
				performWithDelay( self,function()
					self:aiOutCard()
				end,0.5 )
			end
		end
		-- 移动玩家的出牌到ai的牌堆
		self:moveCardsFromOutToPaiDui( self._playerOutCards,self.ImageBeiAI,self._aiPaiDuiCards,call_ai_out,true,0.2 )
	end
	-- 移动ai的出牌到ai的牌堆
	self:moveCardsFromOutToPaiDui( self._aiOutCards,self.ImageBeiAI,self._aiPaiDuiCards,call_move_player,true,0.2 )
	
end

function GamePlay:excutePlayerWinPokerAction()
	local call_move_player = function()
		local call_player_out = function()
			-- 玩家出牌
			if #self._aiPaiDuiCards <= 1 then
				self:isGameOver(2)
			else
				performWithDelay( self,function()
					self:turnPlayerOutCard()
				end,0.5 )
			end
		end
		-- 移动玩家的出牌到玩家的牌堆
		self:moveCardsFromOutToPaiDui( self._playerOutCards,self.ImageBeiPlayer,self._playerPaiDuiCards,call_player_out,false,0.2 )
	end
	-- 移动ai的出牌到玩家的牌堆
	self:moveCardsFromOutToPaiDui( self._aiOutCards,self.ImageBeiPlayer,self._playerPaiDuiCards,call_move_player,false,0.2 )
end


function GamePlay:moveCardsFromOutToPaiDui( outCards,paiDuiNode,paiDuiCards,callBack,needFlippedY,actionTime )
	assert( outCards," !! outCards is nil !! " )
	assert( paiDuiNode," !! paiDuiNode is nil !! " )
	assert( paiDuiCards," !! paiDuiCards is nil !! " )
	assert( actionTime," !! actionTime is nil !! " )
	assert( #outCards > 0," !! #outCards must be > 0 !! " )
	for i,v in ipairs( outCards ) do
		v:showBei()
		local world_pos = paiDuiNode:getParent():convertToWorldSpace( cc.p( paiDuiNode:getPosition() ) )
		local node_pos = v:getParent():convertToNodeSpace( world_pos )
		local delay = cc.DelayTime:create(0.1 * i)
		local move_to = cc.MoveTo:create( actionTime,node_pos )
		local call_set = cc.CallFunc:create( function()
			-- 创建poker
			local poker = NodePoker.new( self,v:getNumIndex() )
			paiDuiNode:addChild( poker,0 )
			table.insert( paiDuiCards,1,poker )

			local panel_size = self.ImageBeiAI:getContentSize()
			local pos = cc.p( panel_size.width / 2,panel_size.height / 2 + 7 )
			poker:setPosition( pos )

			if i == #outCards then
				-- 清除出牌
				for k,v in ipairs(outCards) do
					outCards[k] = nil
				end
				-- needFlippedY为true 表示 ai
				self:reSetZOrderAndPosCards( paiDuiCards,needFlippedY )
				if callBack then
					callBack()
				end
			end
		end )
		local remove = cc.RemoveSelf:create()
		v:runAction( cc.Sequence:create({ delay,move_to,call_set,remove }) )
	end
end

function GamePlay:reSetZOrderAndPosCards( paiDuiCards,needFlippedY )
	assert( paiDuiCards," !! paiDuiCards is nil !! " )
	local panel_size = self.ImageBeiAI:getContentSize()
	local pos = cc.p( panel_size.width / 2,panel_size.height / 2 + 7 )
	for i,v in ipairs( paiDuiCards ) do
		v:setPosition( cc.p( pos.x - i * 1,pos.y + i * 1 ) )
		v:setLocalZOrder( i )
		if needFlippedY then
			v._image:getVirtualRenderer():getSprite():setFlippedY( true )
		end
	end
end

function GamePlay:isGameOver( winType )
	if winType == 1 then
		-- ai 赢
	elseif winType == 2 then
		-- 玩家赢
	end
end

function GamePlay:showPass()
	self.ButtonPass:setVisible( true )
	if not self._schedulePassMark then
		self._schedulePassMark = true
		self._passIndex = 1
		self:schedule( function()
			local path = ""
			if self._passIndex % 2 ~= 0 then
				path = "image/play/pass.png"
			else
				path = "image/play/pass2.png"
			end
			self._passIndex = self._passIndex + 1
			self.ButtonPass:loadTexture( path,1 )
		end,0.5 )
	else
		self:startSchedule()
	end
end

function GamePlay:hidePass()
	self.ButtonPass:setVisible( false )
	if self._schedulePassMark then
		self:stopSchedule()
	end
end

function GamePlay:clickPass()
	self:hidePass()
	-- 直接ai赢
	self:excuteAIWinPokerAction()
end


return GamePlay