

local Solider = class("Solider",BaseNode) 



Solider.STATUS = {
	CREATE = 0, -- 刚刚创建的状态
	MARCH = 1, -- 行军状态
	CANFIGHT = 2, -- 可以战斗的状态
	FIGHTMOVE = 3, -- 战斗移动状态
	FIGHT = 4, -- 正在战斗的状态
	FIGHT_HALF = 5, -- 战斗状态，但是没有被人攻击
}

function Solider:ctor( soliderId,gameLayer )
	assert( soliderId," !! soliderId is nil !! " )
	assert( gameLayer," !! gameLayer is nil !! " )
	Solider.super.ctor( self,"Solider" )
	self:addCsb( "csbfensuizhan/NodeSolider.csb" )
	self._id = soliderId
	self._gameLayer = gameLayer
	self._track = random( 1,10 )
	self._guid = getGUID()
	self._config = solider_config[self._id]
	self._status = self.STATUS.CREATE

	self._aim = nil -- 目标敌人
	self._isAim = nil -- 是谁的目标
	self._beAttack = false --是否处于被攻击
	self._modeType = "" -- 该人物的类型 people:玩家 enemy:电脑
end



function Solider:setDirection( strType )
	if strType == "left" then
		self.Icon:getVirtualRenderer():getSprite():setFlipX( true )
	elseif strType == "right" then
		self.Icon:getVirtualRenderer():getSprite():setFlipX( false )
	end
end

function Solider:onEnter()
	Solider.super.onEnter( self )
end


function Solider:playFrameAction( frameName )
	if self._curFrameName == frameName then
		return
	end
	self._curFrameName = frameName
	local index = self._config[frameName].fstart
	self.Icon:stopAllActions()
	schedule( self.Icon,function()
		local path = self._config[frameName].path..index..".png"
		self.Icon:loadTexture( path,1 )
		index = index + 1
		if index > self._config[frameName].fend then
			index = self._config[frameName].fstart
		end
	end,0.1 )
end
-- 播放idle动画
function Solider:playIdle()
	self:playFrameAction("idle_frame")
end
-- 播放移动动画
function Solider:playMove()
	self:playFrameAction("move_frame")
end
--播放攻击动画
function Solider:playAttack()
	self:playFrameAction("attack_frame")
end
-- 播放死亡动画
function Solider:playDead()
	self:playFrameAction("dead_frame")
end


function Solider:getTrack()
	return self._track
end

function Solider:updateStatus()
	-- if self._status == self.STATUS.CREATE then
	-- 	-- 进入行军状态
	-- 	self._status = self.STATUS.MARCH
	-- 	self:playMove()
	-- elseif self._status == self.STATUS.MARCH then
	-- 	-- 行军状态
	-- 	self:moveToBattleRegion()
	-- elseif self._status == self.STATUS.CANFIGHT then
	-- 	-- 可以战斗的状态 进行搜索敌人
	-- 	self:searchEnemy()
	-- elseif self._status == self.STATUS.FIGHTMOVE then
	-- 	-- 战斗行军状态
	-- end
end

-- 子类重写
function Solider:moveToBattleRegion()

end


function Solider:searchEnemy()

end

function Solider:getStatus()
	return self._status
end

function Solider:setStatus( status )
	self._status = status
end

-- 设置目标
function Solider:setAim( node )
	self._aim = node
end
function Solider:getAim()
	-- body
end
-- 设置是谁的目标
function Solider:setIsAim( node )
	self._isAim = node
end
function Solider:getIsAim()
	-- body
end

-- 移动到目标位置
function Solider:moveToDestPoint( destPoint,callBack  )
	local now_pos = cc.p( self:getPosition() )
	local end_pos = clone( destPoint )
	local dis = cc.pGetDistance( now_pos,end_pos )
	local time = dis / self._config.speed

	local move_to = cc.MoveTo:create( time,end_pos )
	local call_back = cc.CallFunc:create( function()
		if callBack then
			callBack()
		end
	end )
	local seq = cc.Sequence:create( { move_to,call_back } )
	self:runAction( seq )
end




return Solider