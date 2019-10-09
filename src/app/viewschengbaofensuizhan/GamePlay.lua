
local LoadPersonLayer = import(".LoadPersonLayer")

local Build = import(".Build")
local Soldier = import(".Soldier")
local Enemy = import(".Enemy")
local GamePlay = class( "GamePlay",BaseLayer )

function GamePlay:ctor( param )
	assert( param," !! param is nil !! " )
	assert( param.name," !! param.name is nil !! " )
	GamePlay.super.ctor( self,param.name )

	self:addCsb("csbchengbaofensuizhan/GamePlay.csb")

	-- self._loadPersonLayer = LoadPersonLayer.new(self)
	-- self:addChild( self._loadPersonLayer )

	

	-- 自己士兵的容器
	self._soldierList = {}
	-- 电脑士兵的容器
	self._enemyList = {}
end

function GamePlay:onEnter()
	GamePlay.super.onEnter( self )
	-- 创建城墙
	self:createBuildWall()
	-- 创建敌人
	self._enemyScheduleTime = random( 1,3 )
	self._enemyCurrentTime = 1
	self._enemyTotalCount = 1
	self._enemyCurrentCount = 0

	-- 测试 创建士兵
	self:createSoldier(1,cc.p( 150,100 ) )
	-- self:createSoldier(2,cc.p( 100,100 ) )


	self:schedule( function()
		self:createEnemy()
	end,1 )
end

function GamePlay:createBuildWall()
	-- 1:创建自己的城墙
	local build_own = Build.new( 1,self )
	self:addChild( build_own )
	build_own:setPosition( cc.p( 100,display.cy ) )
	-- 写入容器
	local meta1 = { type = "build",node = build_own }
	table.insert( self._soldierList,met1 )
	-- 2:创建敌人的城墙
	local build_enemy = Build.new( 1,self )
	self:addChild( build_enemy )
	build_enemy:setPosition( cc.p( display.width - 100,display.cy ) )
	-- 写入容器
	local meta2 = { type = "build",node = build_enemy }
	table.insert( self._enemyList,meta2 )
end


-- 创建自己的士兵
function GamePlay:createSoldier( soldierId,woldPos )
	local soldier = Soldier.new( soldierId,self )
	self:addChild( soldier )
	soldier:setPosition( woldPos )

	-- 写入容器
	local meta = { type = "person",node = soldier }
	table.insert( self._soldierList,meta )
end

-- 创建电脑的士兵
function GamePlay:createEnemy()
	self._enemyCurrentTime = self._enemyCurrentTime + 1
	if self._enemyCurrentTime >= self._enemyScheduleTime then
		self._enemyCurrentTime = 0
		self._enemyScheduleTime = random( 1,3 )
		-- 创建敌人 随机1-2个
		local enemy_num = random(1,1)
		for i = 1,enemy_num do
			-- 随机id
			local enemy_id = random( 1,#chengbao_config.enemy )
			local enemy_node = Enemy.new( enemy_id,self )
			self:addChild( enemy_node )

			-- 写入容器
			local meta = { type = "person",node = enemy_node }
			table.insert( self._enemyList,meta )

			-- 位置也需要随机
			enemy_node:setPosition( display.cx + random(200,300),display.cy + random( -200,200 ) )
		end
		self._enemyCurrentCount = self._enemyCurrentCount + enemy_num
		if self._enemyCurrentCount >= self._enemyTotalCount then
			self:unSchedule()
		end
	end
end




return GamePlay