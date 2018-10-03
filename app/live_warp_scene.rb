class LiveWarpScene < SKScene
	def initWithSize(size)
		super
		
		self.anchorPoint = CGPointMake(0.5, 0.5) # anchorPoint is prop of SKScene
		self.name = "Scene"
    
		self
	end

	def didMoveToView(view)
		removeAllChildren
    add_leaf_sprite
    add_control_sprites(@leaf)
		prepare_warps
		@leaf.warpGeometry = @warps[:base]
	end

	def renew_leaf_sprite
		@leaf.removeFromParent if @leaf != nil
		add_leaf_sprite
		@control_nodes.each { |e| e.removeFromParent if e != nil }
		add_control_sprites(@leaf)
		@leaf
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

	def add_control_sprites(image)
		control_vertices = [
			[[0.0, 1.0], [0.5, 1.0], [1.0, 1.0]], # top row: left, center, right
			[[0.0, 0.5], [0.5, 0.5], [1.0, 0.5]], # middle row: left, center, right
			[[0.0, 0.0], [0.5, 0.0], [1.0, 0.0]]  # bottom row: left, center, right
			]
		control_vectors = control_vertices.reverse.flatten(1)
		@src_ptr = make_vectors_pointer(control_vectors)
		
		@control_nodes = []
		control_vectors.each { |e| @control_nodes << add_control_node_sprite(image, e) }
	end

	def add_control_node_sprite(targetnode, gridpoint)
		shape = SKShapeNode.shapeNodeWithEllipseOfSize(CGSizeMake(10, 10))
		shape.name = "Control"
		shape.fillColor = UIColor.redColor
		shape.position = gridpoint_to_cgpoint(gridpoint, targetnode.frame.size)
		targetnode.addChild(shape)
		shape
	end
	
	def prepare_warps
		prepare_warps_base
	end
	
	def prepare_warps_base
		@warps ||= {}
		@warps[:base] = SKWarpGeometryGrid.gridWithColumns(1, rows: 1)
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
	
	def update_leaf
		dest_vectors = @control_nodes.map { |n| warp_position(n) }
		dest_ptr = make_vectors_pointer(dest_vectors)
		
		# Hand craft warp. We have vectors not 3d vertices here and can't use #make_warp_grid.
		warp = SKWarpGeometryGrid.gridWithColumns(2, rows: 2, 
			sourcePositions: @src_ptr,
			destPositions: dest_ptr)
		@leaf.warpGeometry = warp		
	end

	def put_dest_vertices
		# Well, it's one way to go...
		dest_vertices = @control_nodes.map { |n| warp_position(n) }
		arrarr = dest_vertices.each_slice(3).to_a.reverse
		lines = arrarr.map { |row| s="["; 
			row.each { |e| s << "[%0.2f, %0.2f], " % e }; s.chomp(", ").concat("],") }
		lines[lines.length-1] = lines.last.chomp(",")
		puts "Vertices:"
		puts lines
	end
	
	def warp_position(node)
		cgpoint_to_gridpoint(node.position, node.parent.frame.size)
	end

	# Lots of ruby ways to do this. Revisit!!!
	def cgpoint_to_gridpoint(position, size)
		xdir = position.x / size.width * 2
		ydir = position.y / size.height * 2
		[xdir / 2 + 0.5, ydir / 2 + 0.5]
	end

	def gridpoint_to_cgpoint(gridpoint, size)
		xdir = 2 * (gridpoint[0] - 0.5)
		ydir = 2 * (gridpoint[1] - 0.5)		
		CGPointMake(xdir * (size.width / 2), ydir * (size.height / 2))
	end
	
	def touchesBegan(touches, withEvent: _)
		touch = touches.allObjects.first
		node = nodeAtPoint(touch.locationInNode(self))
		case node.name
		when "Control"
			@moving_node = node
			@moving_node.fillColor = UIColor.yellowColor
		when "Leaf"
			put_dest_vertices
		else #when "Scene"
			renew_leaf_sprite
		end
	end
	
	def touchesMoved(touches, withEvent: _)
		return if @moving_node == nil
		touch = touches.allObjects.first
		@moving_node.position = touch.locationInNode(@moving_node.parent)
		update_leaf
	end
	
	def touchesEnded(touches, withEvent: _)
		return if @moving_node == nil
		touch = touches.allObjects.first
		@moving_node.position = touch.locationInNode(@moving_node.parent)
		@moving_node.fillColor = UIColor.redColor
		@moving_node = nil
	end
end
