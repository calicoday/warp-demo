# Warp-demo

A small RubyMotion for iOS sample app exploring Sprite Kit's SKWarpGeometry.

Build and run in the iOS simulator with `rake` from the project directory.

The app can be built three ways, depending on which of one these three lines in view_controller.rb is uncommented:

    #@scene = DemoWarpScene.sceneWithSize(sk_view.frame.size)		    		
    #@scene = DevWarpScene.sceneWithSize(sk_view.frame.size)		    		
    @scene = LiveWarpScene.sceneWithSize(sk_view.frame.size)		    		

and these:

* `DemoWarpScene` simply displays a sequence of warp transformations on touch/click anywhere (see video [warp-demo.mov](warp-demo.mov)).
* `DevWarpScene` does the same as `DemoWarpScene` but is organized with less commentary and methods for easier mucking about during development.
* `LiveWarpScene` presents the reference leaf image with border plus 9 control nodes you can drag-and-drop, warping the leaf live. If you touch/click within the leaf border, the leaf resets. Touch/click outside and the current control node positions are printed to the console in an array suitable for copy-and-pasting into code (formed as warp grid vertices are dealt with here). Looks like this:

[LiveWarpScene image](warp-demo.png)

# Notes on That Time Cal Made a RubyMotion Pointer

When I came to try Sprite Kit's SKWarpGeometry class, I couldn't find any RubyMotion sample code to play with and found my own way forward. Here's how I got unstuck, this time, for what it's worth.

The SKWarpGeometryGrid.initWithColumns initializer wants parameters `sourcePositions` and `destPositions`. The Obj-C Apple docs say these are type `const vector_float2 *` and `vector_float2` is `typedef simd_float2 vector_float2` which means nothing to me. 

Searching the RubyMotion BridgeSupport SpriteKit.xml file for 'vector_float2' finds:

	<struct name="vector_float2" type="{_vector_float2="x"f"y"f}">
		<field declared_type="float" name="x" type="f"/>
		<field declared_type="float" name="y" type="f"/>
	</struct>

Oh, ho. Well, a CGPoint is a struct too and in BridgeSupport CoreGraphics.xml we find:

	<struct name="CGPoint" type="{CGPoint="x"f"y"f}" type64="{CGPoint="x"d"y"d}">
		<field declared_type="CGFloat" name="x" type="f" type64="d"/>
		<field declared_type="CGFloat" name="y" type="f" type64="d"/>
	</struct>
	
and the handy

	<function inline="true" name="CGPointMake">
		<arg declared_type="CGFloat" name="x" type="f" type64="d"/>
		<arg declared_type="CGFloat" name="y" type="f" type64="d"/>
		<retval declared_type="CGPoint" type="{CGPoint=ff}" type64="{CGPoint=dd}"/>
	</function>

that we use so often, eg `sprite.position = CGPointMake(50, 50)`

So, SKVectorFloat2Make or something...? Seems not.

In the [RubyMotion Runtime Guide for iOS and OS X](http://www.rubymotion.com/developers/guides/manuals/cocoa/runtime/), Section '3.2. Structures', it says:

> C structures are mapped to classes in RubyMotion. Structures can be created in Ruby and passed to APIs expecting C structures.  

and give an example using CGPoint. But I haven't yet been able to make that work here -- there would need to be a SKVectorFloat2 class or similar in SpriteKit.xml, surely? There's an enum SKAttributeTypeVectorFloat2 which seems to be relevant to an SKUniform which seems to be relevant to 'a custom OpenGL or OpenGL ES shader'...? But I can't find a way to apply that here. Need to come back to this. 

From Hwee-Boon Yar's helpful [RubyMotion Tutorial for Objective C Developers](http://hboon.com/rubymotion-tutorial-for-objective-c-developers/):

> There isn't a built-in way to manipulate pointers in Ruby like in Objective C. Instead, RubyMotion provides a Pointer class where you specify the type of pointer as a symbol, you'll use :object for all objects that are not C primitives and a corresponding symbol for each primitive type (e.g. :char for char*)

and back to the Runtime Guide, Section '3.5. Pointers':

> Pointers are a very basic data type of the C language. Conceptually, a pointer is a memory address that can point to an object. ...
> RubyMotion introduces the Pointer class in order to create and manipulate pointers. The type of the pointer to create must be provided in the new constructor. A pointer instance responds to [] to dereference its memory address and []= to assign it to a new value.
> ...
> Pointer.new accepts either a String, which should be one of the [Objective-C runtime types](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html) or a Symbol, which should be a shortcut. 

According to that last ref, the 'Type Encodings' section of the (archived) Objective-C Runtime Programming Guide, the code for a structure will take the form:

	{name=type...}
	
Ah! And back in the BridgeSupport SpriteKit.xml, we find in class SKWarpGeometryGrid:

	<method class_method="true" selector="gridWithColumns:rows:sourcePositions:destPositions:">
		<arg declared_type="NSInteger" index="0" name="cols" type="i" type64="q"/>
		<arg declared_type="NSInteger" index="1" name="rows" type="i" type64="q"/>
		<arg const="true" declared_type="vector_float2 * _Nullable" index="2" name="sourcePositions" type="^{_vector_float2=ff}"/>
		<arg const="true" declared_type="vector_float2 * _Nullable" index="3" name="destPositions" type="^{_vector_float2=ff}"/>
		<retval declared_type="instancetype _Nonnull" type="@"/>
	</method>

Voilà, `sourcePositions` and `destPositions` will each want a Pointer.new("{_vector_float2=ff}", number_of_position_vectors).

Last step is to get the values into the newly alloc'd contiguous structs.

# Sources 

* (Image asset) Maple leaf from an image (maple-leaves-482678_1280.png) by user stux at pixabay.com (cc0 licence)

* RubyMotion docs [RubyMotion Runtime Guide for iOS and OS X](http://www.rubymotion.com/developers/guides/manuals/cocoa/runtime/). Section 3.5 Pointers.

* Hwee-Boon Yar post [RubyMotion Tutorial for Objective C Developers](http://hboon.com/rubymotion-tutorial-for-objective-c-developers/#gcd). RubyMotion Pointers, toward the end of the 'More Code Differences' section.

* Google Books preview [MacRuby: The Definitive Guide: Ruby and Cocoa on OS X](https://books.google.ca/books?id=WPhdPzyU1R4C&pg=PA158&lpg=PA158&dq=one_step_deeper+pointers&source=bl&ots=j9X8OZqEgZ&sig=B_DDBvoR_oqZ_TdBd8stbL2c6NA&hl=en&sa=X&ved=2ahUKEwj0rp78vLrdAhVq_4MKHW4dCG0Q6AEwA3oECAcQAQ#v=onepage&q=one_step_deeper%20pointers&f=false). Section 'Pointers' at the end of Chapter 8, pg 157-169.

* Apple docs (Obj-C) [class SKWarpGeometryGrid](https://developer.apple.com/documentation/spritekit/skwarpgeometrygrid?language=objc)

* Stackoverflow post [Spritekit | Swift3 | Applying SKWarpGeometry to nodes](https://stackoverflow.com/questions/40250935/spritekit-swift3-applying-skwarpgeometry-to-nodes). Answer by user user3482617 (Oct 26 '16 at 12:57) has code sample for a single warp of an SKSpriteNode

* Stackoverflow post [Does SpriteKit support dense tessellation of a sprite / texture / shape so it can be warped freely?](https://stackoverflow.com/questions/19779312/does-spritekit-support-dense-tessellation-of-a-sprite-texture-shape-so-it-ca/37884312#37884312). Answer by user Benzi (Jun 17 '16 at 14:37. Edited Nov 7 '16 at 19:10) includes sample Swift code you can paste into a XCode playground. Shows a star and drag points that warp the star live.

* Medium post [Functional swift: All about Closures](https://medium.com/@abhimuralidharan/functional-swift-all-about-closures-310bc8af31dd). To make sense of Swift closure syntax in the above sample code.
