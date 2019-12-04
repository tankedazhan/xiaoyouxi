
local PeopleSolider = import(".PeopleSolider")
local EnemySolider = import(".EnemySolider")
local GameFightOperation = class("GameFightOperation",BaseLayer)

function GameFightOperation:ctor( param )
    assert( param," !! param is nil !! ")
    assert( param.name," !! param.name is nil !! ")
    GameFightOperation.super.ctor( self,param.name )

    self:addCsb( "csbhunzhan/FightLayer2.csb" )

    self._stage = 1
    self._enemyList = {}
    self._peopleList = {}

    self._battleLeftX = self.CenterPanel:getPositionX()
    self._battleRightX = self._battleLeftX + self.CenterPanel:getContentSize().width
end



function GameFightOperation:onEnter()
	GameFightOperation.super.onEnter( self )

	self:loadPeople()
	self:loadEnemy()
end


function GameFightOperation:loadPeople()
	local config = hunfight_config[self._stage].player
	for i,v in ipairs( config ) do
		local people = PeopleSolider:create(v.id,self)
		table.insert( self._peopleList,people )
		self:addChild( people )
		people:playIdle()
		people:setPosition( v.position )
		people.mode = v.mode
	end
end

function GameFightOperation:loadEnemy()
	local config = hunfight_config[self._stage].enemy
	for i,v in ipairs( config ) do
		local solider = EnemySolider:create(v.id,self)
		table.insert( self._enemyList,solider )
		self:addChild( solider )
		solider:setCreatePoint( 2 )
		solider:playIdle()
		solider:setPosition( v.position )
	end
end

-- 获得战斗区域左边的X轴边界
function GameFightOperation:getBattleLeftX()
	return self._battleLeftX
end

-- 获得战斗区域右边的X轴边界
function GameFightOperation:getBattleRightX()
	return self._battleRightX
end

function GameFightOperation:soliderDead( guid,modeType )
	local delete_list = nil
	local reset_dest_list = nil
	if modeType == "people" then
		delete_list = self._peopleList
		reset_dest_list = self._enemyList
	elseif modeType == "enemy" then
		delete_list = self._enemyList
		reset_dest_list = self._peopleList
	end

	-- 移除指针
	for i,v in ipairs( delete_list ) do
		if v:getSoliderGUID() == guid then
			table.remove( delete_list,i )
			break
		end
	end
	-- 其他士兵 重新设置攻击目标
	for i,v in ipairs( reset_dest_list ) do
		v:clearDestByGuid( guid )
		v:removeAttackMyEnemyList( guid )
	end
end


return GameFightOperation