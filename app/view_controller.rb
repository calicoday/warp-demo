class ViewController < UIViewController
  def viewDidLoad
    super

    self.view = sk_view 

    #@scene = DemoWarpScene.sceneWithSize(sk_view.frame.size)		    		
    #@scene = DevWarpScene.sceneWithSize(sk_view.frame.size)		    		
    @scene = LiveWarpScene.sceneWithSize(sk_view.frame.size)		    		
    sk_view.presentScene(@scene)
  end
  
  def sk_view
    @_sk_view ||= SKView.alloc.initWithFrame(CGRectMake(0, 0, 
      UIScreen.mainScreen.bounds.size.width, 
      UIScreen.mainScreen.bounds.size.height))
    @_sk_view.ignoresSiblingOrder = false
    @_sk_view
  end

  def prefersStatusBarHidden
    true
  end
 
  def dealloc
    p "Dealloc #{self}"
    super
  end
end 
