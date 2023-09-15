struct vsOut 
{
	@builtin(position) 	pos	: vec4f,
	@location(0) 		uv	: vec2f,
};

@vertex
fn vertexMain(@location(0) pos: vec2f) -> vsOut
{
	var vsOutput: vsOut;
	vsOutput.pos 	= vec4f(pos, 0.0, 1.0);
	vsOutput.uv 	= pos;

	return vsOutput;
}