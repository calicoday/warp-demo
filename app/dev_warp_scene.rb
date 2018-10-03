class DevWarpScene < SKScene
	def initWithSize(size)
		super
		
		self.anchorPoint = CGPointMake(0.5, 0.5)
		self.name = "Scene"
    
    # Set global ref to this TidyWarpScene so we can call '$w.some_method' from 
    # the RubyMotion REPL (super short for typing live). 
    $w = self
    
		self
	end

	# For use from RubyMotion REPL
	def cmd(msg)
		case msg
		when "meow" then puts "Meow!"
		end
		puts("Done cmd.")
	end
	
	def didMoveToView(view)
		prepare_demo
	end
	
	def touchesBegan(touches, withEvent: _)
		run_demo
	end

	def prepare_demo
		removeAllChildren
		add_leaf_sprite				
		prepare_warps
		@leaf.warpGeometry = @warps[:base]
	end

	def add_leaf_sprite
    sprite = SKSpriteNode.spriteNodeWithImageNamed("maple-leaf-gold.png") 
    sprite.name = "sprite"
    sprite.size = CGSizeMake(280, 280)
	
		shape = SKShapeNode.shapeNodeWithRectOfSize(sprite.frame.size)
		shape.name = "shape"
		shape.lineWidth = 1.0
		shape.strokeColor = UIColor.yellowColor

		all_in_one = SKNode.alloc.init
		all_in_one.addChild(sprite)
		all_in_one.addChild(shape) 

		texture = self.view.textureFromNode(all_in_one)
		@leaf = SKSpriteNode.spriteNodeWithTexture(texture)
		@leaf.name = "Leaf"
		addChild(@leaf)
		@leaf
	end	
	
	def prepare_warps
		prepare_warps_base
		prepare_warps_2x2
		prepare_warps_3x3
		prepare_warps_2x5
	end
	
	def prepare_warps_base
		@warps ||= {}
		@warps[:base] = SKWarpGeometryGrid.gridWithColumns(1, rows: 1)
	end
	
	def prepare_warps_3x3	
		@warps ||= {}
		src_3x3 = [
			[[0.0, 1.0], [0.5, 1.0], [1.0, 1.0]], # top row: left, center, right
			[[0.0, 0.5], [0.5, 0.5], [1.0, 0.5]], # middle row: left, center, right
			[[0.0, 0.0], [0.5, 0.0], [1.0, 0.0]]  # bottom row: left, center, right
			]

		@warps[:squeeze] = make_warp_grid(src_3x3,
			[[[-0.00, 1.00], [0.50, 1.00], [1.00, 1.00]],
			[[0.20, 0.60], [0.50, 0.50], [0.89, 0.50]],
			[[-0.00, 0.00], [0.50, 0.00], [1.00, 0.00]]
			])

		@warps[:pull_center] = make_warp_grid(src_3x3,
			[[[0.00, 1.00], [0.50, 1.00], [1.00, 1.00]],
			[[0.00, 0.50], [0.76, 0.23], [1.00, 0.50]],
			[[0.00, 0.00], [0.50, 0.00], [1.00, 0.00]]
			])

	end

	def squeeze_sides
		SKAction.sequence([
			SKAction.warpTo(@warps[:squeeze], duration: 0.5), 
			SKAction.waitForDuration(0.3), 
			SKAction.warpTo(@warps[:base], duration: 0.5)
			])
	end

	def pull_center
		SKAction.sequence([
			SKAction.warpTo(@warps[:pull_center], duration: 0.5), 
			SKAction.waitForDuration(0.3), 
			SKAction.warpTo(@warps[:base], duration: 0.5)
			])
	end
		
	def prepare_warps_2x2
		@warps ||= {}
		src_2x2 = [
			[[0.0, 1.0], [1.0, 1.0]], # top row: left, right
			[[0.0, 0.0], [1.0, 0.0]]  # bottom row: left, right
			]

		@warps[:diag] = make_warp_grid(src_2x2,
			[[[1.0, 0.0], [1.0, 1.0]], 
			[[0.0, 0.0], [0.0, 1.0]]  
			])
	end

	def diagonal_flip
		SKAction.sequence([
			SKAction.warpTo(@warps[:diag], duration: 0.5), 
			SKAction.waitForDuration(0.3), 
			SKAction.warpTo(@warps[:base], duration: 0.5)
			])
	end
	
	def prepare_warps_2x5
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
	end

	def zigzag
		SKAction.sequence([
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
	end
		
	def make_vectors_pointer(vectors)
		ptr = Pointer.new("{_vector_float2=ff}", vectors.length)
		vectors.each_with_index { |e, i| ptr[i] = e }
		ptr
	end
	
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
