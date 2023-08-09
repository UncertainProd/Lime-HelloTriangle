package;

import lime.graphics.opengl.GLProgram;
import lime.utils.Float32Array;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLShader;
import lime.graphics.RenderContext;
import lime.graphics.WebGLRenderContext;
import lime.app.Application;

class Main extends Application
{
	var gl:WebGLRenderContext;

	static inline final DEFAULT_VERTEX_SHADER = '
	attribute vec4 aPosition;
	attribute vec4 vColor;
	varying vec4 vertexColor;
	
	void main()
	{
		gl_Position = aPosition;
		vertexColor = vColor;
	}
	';
	
	static inline final DEFAULT_FRAGMENT_SHADER = '
	varying vec4 vertexColor;

	void main()
	{
		// gl_FragColor = vec4(1.0, 0.0, 0.5, 1.0);
		gl_FragColor = vertexColor;
	}
	';

	public function new()
	{
		super();
	}

	function createShader(type: Int, source: String)
	{
		source = #if (js && html5) "precision mediump float;\n" #else "#ifdef GL_ES\n"
		+ "#ifdef GL_FRAGMENT_PRECISION_HIGH\n"
		+ "precision highp float;\n"
		+ "#else\n"
		+ "precision mediump float;\n"
		+ "#endif\n"
		+ "#endif\n\n" 
		#end + source;

		var shader: GLShader = gl.createShader(type);
		gl.shaderSource(shader, source);
		gl.compileShader(shader);
		var success: Int = gl.getShaderParameter(shader, gl.COMPILE_STATUS);
		if(success > 0)
		{
			return shader;
		}

		var shaderTypeString = (type == gl.FRAGMENT_SHADER) ? "Fragment" : "Vertex";
		trace('$shaderTypeString SHADER COMPILE ERROR: ${gl.getShaderInfoLog(shader)}');
		gl.deleteShader(shader);
		return null;
	}

	function makeShaderProgram(vertexShader: GLShader, fragmentShader: GLShader)
	{
		var shaderProgram = gl.createProgram();
		gl.attachShader(shaderProgram, vertexShader);
		gl.attachShader(shaderProgram, fragmentShader);
		gl.linkProgram(shaderProgram);

		var success: Int = gl.getProgramParameter(shaderProgram, gl.LINK_STATUS);
		if(success > 0)
		{
			return shaderProgram;
		}

		trace('LINK ERROR: ${gl.getProgramInfoLog(shaderProgram)}');
		gl.deleteProgram(shaderProgram);
		return null;
	}

	var positionBuffer:GLBuffer;
	var positionAttrLocation:Int;
	function makePositionBuffer()
	{
		var positions = [
			0.5, 0.0,
			-0.5, 0.0,
			0.0, 0.5,
		];
		
		positionBuffer = gl.createBuffer();
		gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
		gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(positions), gl.STATIC_DRAW);
		return positionBuffer;
	}

	var colorBuffer:GLBuffer;
	var colorAttrLocation:Int;
	function makeColorBuffer()
	{
		var colors = [
			1.0, 0.0, 0.0,
			0.0, 1.0, 0.0,
			0.0, 0.0, 1.0,
		];
		
		colorBuffer = gl.createBuffer();
		gl.bindBuffer(gl.ARRAY_BUFFER, colorBuffer);
		gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(colors), gl.STATIC_DRAW);
		return colorBuffer;
	}

	var shaderProg:GLProgram;
	override function onWindowCreate()
	{
		super.onWindowCreate();
		gl = window.context.webgl;

		var vertexShader: GLShader = createShader(gl.VERTEX_SHADER, DEFAULT_VERTEX_SHADER);
		var framentShader: GLShader = createShader(gl.FRAGMENT_SHADER, DEFAULT_FRAGMENT_SHADER);

		shaderProg = makeShaderProgram(vertexShader, framentShader);

		positionBuffer = makePositionBuffer();
		positionAttrLocation = gl.getAttribLocation(shaderProg, "aPosition");

		colorBuffer = makeColorBuffer();
		colorAttrLocation = gl.getAttribLocation(shaderProg, "vColor");
	}

	override function render(context:RenderContext)
	{
		super.render(context);
		gl.viewport(0, 0, window.width, window.height);

		gl.clearColor(0.0, 0.0, 0.0, 0.0);
		gl.clear(gl.COLOR_BUFFER_BIT);

		gl.useProgram(shaderProg);

		// enable vertex attribute array at this attribute location
		gl.enableVertexAttribArray(positionAttrLocation);

		gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
		var size = 2; // 2 floats at a time
		var type = gl.FLOAT;
		var normalize = false;
		var stride = 0;
		var offset = 0;
		gl.vertexAttribPointer(positionAttrLocation, size, type, normalize, stride, offset);
		
		gl.enableVertexAttribArray(colorAttrLocation);
		gl.bindBuffer(gl.ARRAY_BUFFER, colorBuffer);
		var size = 3; // 3 floats at a time
		var type = gl.FLOAT;
		var normalize = false;
		var stride = 0;
		var offset = 0;
		gl.vertexAttribPointer(colorAttrLocation, size, type, normalize, stride, offset);

		var primitives = gl.TRIANGLES;
		var arrOffset = 0;
		var count = 3;
		gl.drawArrays(primitives, arrOffset, count);
	}
}
