
varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

void main()
{
	vec4 v_orColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);
	if(v_orColor.a > 0.0 / 255.0){
		gl_FragColor = vec4(5.0/255.0, 5.0/255.0, 5.0/255.0, 55.0/255.0);
	}
	else{
		gl_FragColor = vec4(v_orColor.r,v_orColor.g,v_orColor.b,v_orColor.a);
	}
}
