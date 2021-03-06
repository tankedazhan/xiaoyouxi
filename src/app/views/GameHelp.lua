

local GameHelp = class("GameHelp",BaseLayer)



function GameHelp:ctor( param )
	assert( param," !! param is nil !! ")
    assert( param.name," !! param.name is nil !! ")
    GameHelp.super.ctor( self,param.name )

    local layer = cc.LayerColor:create(cc.c4b(0, 0, 0, 150))
    self:addChild( layer,1 )

    self:addCsb( "csb/LayerHelp.csb",2 )

    -- 帮助
    self:addNodeClick( self.ButtonClose,{ 
        endCallBack = function() self:close() end
    })
end

function GameHelp:onEnter()
    GameHelp.super.onEnter( self )
    UIScaleShowAction( self.MidPanel )
end


function GameHelp:close()
	removeUIFromScene( UIDefine.UI_KEY.Help_UI )
end




return GameHelp