

mouse = {x: 0, y: 0}


# SCENE
scene = new THREE.Scene()

# CAMERA
WIDTH = window.innerWidth
HEIGHT = window.innerHeight
ASPECT = WIDTH / HEIGHT
VIEW_ANGLE = 45
NEAR = 0.1
FAR = 20000
camera = new THREE.PerspectiveCamera(VIEW_ANGLE, ASPECT, NEAR, FAR)
scene.add(camera)
camera.position.set(0, 150, 400)
camera.lookAt(scene.position)

# RENDERER
renderer = 
	if Detector.webgl
		new THREE.WebGLRenderer(antialias: yes)
	else
		new THREE.CanvasRenderer()

renderer.setSize(WIDTH, HEIGHT)
document.body.appendChild(renderer.domElement)


$(window).on "resize", ->
	WIDTH = window.innerWidth
	HEIGHT = window.innerHeight
	ASPECT = WIDTH / HEIGHT
	
	renderer.setSize(WIDTH, HEIGHT)
	camera.aspect = ASPECT
	camera.updateProjectionMatrix()


# CONTROLS
controls = new THREE.OrbitControls(camera, renderer.domElement)

# LIGHTING
light = new THREE.AmbientLight(0xffffff)
scene.add(light)
# FLOOR
###
floorTexture = new THREE.ImageUtils.loadTexture 'images/checkerboard.jpg'
floorTexture.wrapS = floorTexture.wrapT = THREE.RepeatWrapping 
floorTexture.repeat.set(10, 10)
floorMaterial = new THREE.MeshBasicMaterial(map: floorTexture, side: THREE.DoubleSide)
floorGeometry = new THREE.PlaneGeometry(1000, 1000, 10, 10)
floor = new THREE.Mesh(floorGeometry, floorMaterial)
floor.position.y = -0.5
floor.rotation.x = Math.PI / 2
scene.add(floor)
###

# SKYBOX/FOG
skyBoxGeometry = new THREE.BoxGeometry(10000, 10000, 10000)
skyBoxMaterial = new THREE.MeshBasicMaterial(color: 0x000000, side: THREE.BackSide)
skyBox = new THREE.Mesh(skyBoxGeometry, skyBoxMaterial)
scene.add(skyBox)


###################################

canvases = for i in [0..6]
	canvas = document.createElement('canvas')
	canvas.width = canvas.height = 1024
	ctx = canvas.getContext('2d')
	ctx.fillStyle = '#ddd'
	ctx.fillRect(0, 0, canvas.width, canvas.height)
	
	ctx.lineWidth = 5
	ctx.strokeStyle = '#000'
	ctx.strokeRect(0, 0, canvas.width, canvas.height)
	
	canvas

materials = 
	for canvas in canvases
		map = new THREE.Texture(canvas)
		map.needsUpdate = true
		new THREE.MeshLambertMaterial
			color: 0xaaaaaa
			side: THREE.FrontSide
			map: map

faceMaterial = new THREE.MeshFaceMaterial(materials)

productGeometry = new THREE.BoxGeometry(1, 1, 1, 10, 10, 10)
for face in productGeometry.faces
	face.color.setRGB(0, 0, 0.8 * Math.random() + 0.2)

product = new THREE.Mesh(productGeometry, faceMaterial)
product.position.set(0, 0, 0)
scene.add(product)

###################################

unprojector = new THREE.Projector()

$("body").on "mousemove dragover dragenter drop", (e)-> 
	e.preventDefault()
	
	mouse.x = (e.originalEvent.offsetX / window.innerWidth) * 2 - 1
	mouse.y = (e.originalEvent.offsetY / window.innerHeight) * -2 + 1
	
	vector = new THREE.Vector3(mouse.x, mouse.y, 1)
	unprojector.unprojectVector(vector, camera)
	ray = new THREE.Raycaster(camera.position, vector.sub(camera.position).normalize())
	
	intersects = ray.intersectObjects([product])
	
	if mouse.intersect
		mid = mouse.intersect.face.materialIndex
		materials[mid].emissive.setHex(0x000000)
		materials[mid].needsUpdate = true
	
	mouse.intersect = intersects[0]
	
	if mouse.intersect
		mid = mouse.intersect.face.materialIndex
		materials[mid].emissive.setHex(0xa0a0a0)
		materials[mid].needsUpdate = true
	
	# # # # # # # # # # # # # #
	
	dt = e.originalEvent.dataTransfer
	intersect = mouse.intersect
	
	if intersect and e.type isnt 'mousemove'
		
		mid = intersect.face.materialIndex
		
		if e.type is 'drop' and dt?.files?.length
			console.log 'dropped file[s] on box'
			for file in dt.files
				if file.type.match /image/
					fr = new FileReader()
					fr.onload = ->
						materials[mid].map = THREE.ImageUtils.loadTexture(fr.result)
						materials[mid].needsUpdate = true
						intersect.object.geometry.needsUpdate = true
					fr.readAsDataURL(file)

dimensions = []
$("input").each (i)->
	$(@).on("change", ->
		dimensions[i] = $(@).val()
		product.scale.x = dimensions[0] * 10
		product.scale.y = dimensions[1] * 10
		product.scale.z = dimensions[2] * 10
		product.needsUpdate = true
	).trigger("change")

do animate = ->
	requestAnimationFrame(animate)
	renderer.render(scene, camera)
	controls.update()
