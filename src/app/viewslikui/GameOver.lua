
local GameOver = class("GameOver",BaseLayer)


function GameOver:ctor( param )
    assert( param," !! param is nil !! ")
    assert( param.name," !! param.name is nil !! ")
    GameOver.super.ctor( self,param.name )

    local layer = cc.LayerColor:create(cc.c4b(0, 0, 0, 150))
    self:addChild( layer,1 )
    self._layer = layer

    self:addCsb( "csblikui/Over.csb",2 )
    self._score = param.data

    self:addNodeClick( self.ButtonContinue,{
        endCallBack = function ()
            self:clickContinue()
        end
    })

    self:addNodeClick( self.ButtonBack,{
        endCallBack = function ()
            self:clickBack()
        end
    })
   
    self:loadDataUi()
end


function GameOver:onEnter()
    GameOver.super.onEnter( self )
    casecadeFadeInNode( self._csbNode,0.5 )
end

function GameOver:loadDataUi()
    local coin = G_GetModel("Model_LiKui"):getInstance():getCoin()
    self.Text1:setVisible( false )
    self.Text2:setVisible( false )
    self.TextCoin:setVisible( false )
    self.TextPochan:setVisible( false )
    self.ButtonBack:setVisible( false )
    self.ButtonContinue:setVisible( false )
    if coin <= 0 then
        self.TextPochan:setVisible( true )
        self.ButtonBack:setVisible( true )
    else
        self.Text1:setVisible( true )
        self.Text2:setVisible( true )
        self.TextCoin:setVisible( true )
        self.ButtonContinue:setVisible( true )
        self.TextCoin:setString( math.abs(self._score) )
        if self._score >= 0 then
            self.Text1:setString("本局赢得了")
        else
            self.Text1:setString("本局输掉了")
        end
    end

    local coin_pos = cc.p( self.Text1:getPosition())
    coin_pos.x = coin_pos.x + 20
    self.TextCoin:setPosition( coin_pos )
    local jin_pos = cc.p( self.TextCoin:getPosition())
    local size = self.TextCoin:getContentSize()
    jin_pos.x = jin_pos.x + 40 + size.width
    self.Text2:setPosition( jin_pos )
end


function GameOver:clickContinue()
    removeUIFromScene( UIDefine.LIKUI_KEY.Over_UI )
    removeUIFromScene( UIDefine.LIKUI_KEY.Play_UI )
    addUIToScene( UIDefine.LIKUI_KEY.Play_UI )
end


function GameOver:clickBack()
    removeUIFromScene( UIDefine.LIKUI_KEY.Over_UI )
    removeUIFromScene( UIDefine.LIKUI_KEY.Play_UI )
    addUIToScene( UIDefine.LIKUI_KEY.Start_UI )
end


return GameOver