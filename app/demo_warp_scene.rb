class DemoWarpScene < SKScene
	def initWithSize(size)
		super
		
		self.anchorPoint = CGPointMake(0.5, 0.5)
		self.name = "Scene"
    
		self
	end
	
	def didMoveToView(view)
		prepare_demo
		# Set warpGeometry to base before the first warp action or it will delay and lurch.
		@leaf.warpGeometry = @warps[:base]
		
	end
	
	def touchesBegan(touches, withEvent: _)
		run_demo
	end

	def prepare_demo
		removeAllChildren
		
    sprite = SKSpriteNode.spriteNodeWithImageNamed("maple-leaf-gold.png") 
    sprite.name = "sprite"
    sprite.size = CGSizeMake(280, 280)
	
		# To make the effects of a warp more clear, add a border to the target image 
		# that will be warped in concert with the target. We can use an SKShapeNode 
		# but it won't be SKWarpable in itself. Adding it to an SKEffectNode or 
		# converting it to a texture and creating an SKSpriteNode from that will get us
		# warp capability. 		
		shape = SKShapeNode.shapeNodeWithRectOfSize(sprite.frame.size)
		shape.name = "shape"
		shape.lineWidth = 1.0
		shape.strokeColor = UIColor.yellowColor

		# Adding the shape to an SKEffectNode to warp would go like this:
		effectnode = SKEffectNode.alloc.init
		effectnode.name = "effectnode"
		#effectnode.addChild(shape)
		
		# Or make a texture from the shape and make an SKSpriteNode from the
		# texture to warp, like this:
		texture = self.view.textureFromNode(shape)
		border_sprite = SKSpriteNode.spriteNodeWithTexture(texture)
		border_sprite.name = "border_sprite"
		
		# However, we then have two nodes we want to warp in tandem (image and border).
		# Multiple SKActions (including warpTo) can be grouped all sorts of ways
		# but then are applied to a single node at a time. We can apply the same
		# actions to the target image, then to the border but it's fragile and they won't
		# be quite synchronized (lag is sometimes visible).
		
		# Easiest here is to make image sprite and border shape one texture sprite.
		all_in_one = SKNode.alloc.init
		all_in_one.addChild(sprite)
		all_in_one.addChild(shape) 

		texture = self.view.textureFromNode(all_in_one)
		@leaf = SKSpriteNode.spriteNodeWithTexture(texture)
		@leaf.name = "Leaf"
		addChild(@leaf)
					
		# === squeeze sides effect ===
		
		# SKWarpGeometryGrid wants two arrays of normalized vertex positions, 
		# sourcePositions and destPositions, defining the positions of the vertices 
		# in the un-warped geometry and the final, warped destination positions, 
		# respectively. Both are one-dimensional arrays in "row-major" order and
		# the origin of the vertex positions is in the bottom left (the first item 
		# in the array refers to the position at the bottom left and 
		# the last item refers to the position at the top right).
		
		default_vectors = [
			[0.0, 0.0], [0.5, 0.0], [1.0, 0.0], # bottom row: left, center, right
			[0.0, 0.5], [0.5, 0.5], [1.0, 0.5], # middle row: left, center, right
			[0.0, 1.0], [0.5, 1.0], [1.0, 1.0], # top row: left, center, right
			]
			
		# Awkward for the eye, having the bottom-left point at the top-left 
		# in the code, and so on. Easy in Ruby to wrap the points in rows
		# and the rows in an outer array, then we can edit the values with 
		# the top-left at the top-left and reverse the rows and flatten(1)
		# before feeding the method call. So,					
		src_from_top_at_top = [
			[[0.0, 1.0], [0.5, 1.0], [1.0, 1.0]], # top row: left, center, right
			[[0.0, 0.5], [0.5, 0.5], [1.0, 0.5]], # middle row: left, center, right
			[[0.0, 0.0], [0.5, 0.0], [1.0, 0.0]]  # bottom row: left, center, right
			].reverse.flatten(1)
		# => [[0.0, 0.0], [0.5, 0.0], ... [0.5, 1.0], [1.0, 1.0]]
		# like we started with.

		src_ptr = Pointer.new("{_vector_float2=ff}", src_from_top_at_top.length)
		src_from_top_at_top.each_with_index { |e, i| src_ptr[i] = e }

		# And now what we want to warp into...
		vectors_squeeze = [
			[[-0.00, 1.00], [0.50, 1.00], [1.00, 1.00]],
			[[0.20, 0.60], [0.50, 0.50], [0.89, 0.50]],
			[[-0.00, 0.00], [0.50, 0.00], [1.00, 0.00]]
			].reverse.flatten(1)
			
		# Made and filled one Pointer by hand above, to see it in context. 
		# Now put it in a method, #make_vectors_pointer.
		
		dest_ptr = make_vectors_pointer(vectors_squeeze)
		
		# As sourcePositions and destPositions are one-dimensional arrays,
		# we need to specify the number of columns and rows the vertices describe,
		# ONE LESS than the number of horizontal or vertical vertices, respectively.
		
		warp_squeeze = SKWarpGeometryGrid.gridWithColumns(2, 
			rows: 2,
			sourcePositions: src_ptr,
			destPositions: dest_ptr)

		# Warp geometry grids can be reused in different actions, with different options.
		# Collect them in a hash.
		
		@warps ||= {}
		@warps[:squeeze] = warp_squeeze
		
		# Have SKWarpGeometryGrid generate a default warp for returning to neutral.
		@warps[:base] = SKWarpGeometryGrid.gridWithColumns(1, rows: 1)
		
		# === pull center effect ===
		
		# New transformation, again from the default_vectors above
		# Put making the Pointers and creating the SKWarpGeometryGrid in 
		# method #make_warp_grid, and we won't get the columns and
		# rows vs horizontal and vertical vertices counts muddled.
		
		src_3x3 = [
			[[0.0, 1.0], [0.5, 1.0], [1.0, 1.0]], # top row: left, center, right
			[[0.0, 0.5], [0.5, 0.5], [1.0, 0.5]], # middle row: left, center, right
			[[0.0, 0.0], [0.5, 0.0], [1.0, 0.0]]  # bottom row: left, center, right
			]
		# Let #make_warp_grid do the .reverse.flatten(1) every time.

		# Why [0.76, 0.23] not [0.75, 0.25]? Found these vertices using LiveWarpScene. 
		# Could edit here but they're close enough.
		@warps[:pull_center] = make_warp_grid(src_3x3,
			[[[0.00, 1.00], [0.50, 1.00], [1.00, 1.00]],
			[[0.00, 0.50], [0.76, 0.23], [1.00, 0.50]],
			[[0.00, 0.00], [0.50, 0.00], [1.00, 0.00]]
			])

		# === diagonal flip effect ===
		
		# Warp grid can be other than 3x3, eg 2x2:		
		src_2x2 = [
			[[0.0, 1.0], [1.0, 1.0]], # top row: left, right
			[[0.0, 0.0], [1.0, 0.0]]  # bottom row: left, right
			]

		# Diagonal flip: swap top-left with bottom-right
		@warps[:diag] = make_warp_grid(src_2x2,
			[[[1.0, 0.0], [1.0, 1.0]], 
			[[0.0, 0.0], [0.0, 1.0]]  
			])

		# === zigzag effect ===
		
		# Warp grid must be rectangular but not necessarily square, eg 2x5:		
		src_2x5 = [
			[[0.0, 1.0], [0.25, 1.0], [0.5, 1.0], [0.75, 1.0], [1.0, 1.0]], 
			[[0.0, 0.5], [0.25, 0.5], [0.5, 0.5], [0.75, 0.5], [1.0, 0.5]], 
			[[0.0, 0.0], [0.25, 0.0], [0.5, 0.0], [0.75, 0.0], [1.0, 0.0]]  
			] 

		@warps[:zig_one] = make_warp_grid(src_2x5,
			[[[0.1, 1.0], [0.30, 1.05], [0.5, 1.0], [0.75, 1.0], [1.0, 1.0]], 
			[[0.1, 0.5], [0.30, 0.55], [0.5, 0.5], [0.75, 0.5], [1.0, 0.5]], 
			[[0.1, 0.0], [0.30, 0.05], [0.5, 0.0], [0.75, 0.0], [1.0, 0.0]]  
			])
			
		# And we can have multiple stages...
		@warps[:zig_two] = make_warp_grid(src_2x5,
			[[[0.2, 1.0], [0.35, 1.1], [0.5, 1.0], [0.75, 1.0], [1.0, 1.0]], 
			[[0.2, 0.5], [0.35, 0.6], [0.5, 0.5], [0.75, 0.5], [1.0, 0.5]], 
			[[0.2, 0.0], [0.35, 0.1], [0.5, 0.0], [0.75, 0.0], [1.0, 0.0]]  
			])

		@warps[:zig_three] = make_warp_grid(src_2x5,
			[[[0.2, 1.0], [0.35, 1.1], [0.5, 1.0], [0.70, 1.05], [0.9, 1.0]], 
			[[0.2, 0.5], [0.35, 0.6], [0.5, 0.5], [0.70, 0.55], [0.9, 0.5]], 
			[[0.2, 0.0], [0.35, 0.1], [0.5, 0.0], [0.70, 0.05], [0.9, 0.0]]  
			])

		@warps[:zig_four] = make_warp_grid(src_2x5,
			[[[0.2, 1.0], [0.35, 1.1], [0.5, 1.0], [0.65, 1.1], [0.8, 1.0]], 
			[[0.2, 0.5], [0.35, 0.6], [0.5, 0.5], [0.65, 0.6], [0.8, 0.5]], 
			[[0.2, 0.0], [0.35, 0.1], [0.5, 0.0], [0.65, 0.1], [0.8, 0.0]]  
			])
				
		# End of prep. Hook running through the warps to #touchesBegan.
	end

	# Vectors here is an array of pairs to fill vector_float2 structs.
	# Any '.reverse.flatten(1)' should have happened before this.
	def make_vectors_pointer(vectors)
		ptr = Pointer.new("{_vector_float2=ff}", vectors.length)
		vectors.each_with_index { |e, i| ptr[i] = e }
		ptr
	end
	
	# Expects 3d arrays (pairs in rows in an outer array) with the
	# row holding the top vertices first.
	def make_warp_grid(from_vertices, to_vertices)
		columns = from_vertices[0].length - 1
		rows = from_vertices.length - 1
		
		src_ptr = make_vectors_pointer(from_vertices.reverse.flatten(1))
		dest_ptr = make_vectors_pointer(to_vertices.reverse.flatten(1))
		
		SKWarpGeometryGrid.gridWithColumns(columns, 
			rows: rows,
			sourcePositions: src_ptr,
			destPositions: dest_ptr)
	end

	def run_demo
		squeeze_sides = SKAction.sequence([
			SKAction.warpTo(@warps[:squeeze], duration: 0.5), 
			SKAction.waitForDuration(0.3), 
			SKAction.warpTo(@warps[:base], duration: 0.5)
			])
		pull_center = SKAction.sequence([
			SKAction.warpTo(@warps[:pull_center], duration: 0.5), 
			SKAction.waitForDuration(0.3), 
			SKAction.warpTo(@warps[:base], duration: 0.5)
			])
		diagonal_flip = SKAction.sequence([
			SKAction.warpTo(@warps[:diag], duration: 0.5), 
			SKAction.waitForDuration(0.3), 
			SKAction.warpTo(@warps[:base], duration: 0.5)
			])
		zigzag = SKAction.sequence([
			SKAction.warpTo(@warps[:zig_one], duration: 0.3), 
			SKAction.waitForDuration(0.3), 
			SKAction.warpTo(@warps[:zig_two], duration: 0.3),
			SKAction.waitForDuration(0.3), 
			SKAction.warpTo(@warps[:zig_three], duration: 0.3), 
			SKAction.waitForDuration(0.3), 
			SKAction.warpTo(@warps[:zig_four], duration: 0.3), 
			SKAction.waitForDuration(0.3),
			SKAction.warpTo(@warps[:base], duration: 0.5)
			])

 		@leaf.warpGeometry = @warps[:base]		
		@leaf.runAction(SKAction.sequence([
			squeeze_sides,
			SKAction.waitForDuration(0.3),
			pull_center,
			SKAction.waitForDuration(0.3),
			diagonal_flip,
			SKAction.waitForDuration(0.3),
			zigzag
			]))
	end
		
end
