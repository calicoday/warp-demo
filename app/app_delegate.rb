class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @view_controller = ViewController.alloc.init #.new
    @view_controller.title = 'warp-demo'
    @view_controller.view.backgroundColor = UIColor.whiteColor

    UIApplication.sharedApplication.setIdleTimerDisabled(true)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    @window.rootViewController = @view_controller
    @window.makeKeyAndVisible

    true
  end
end
