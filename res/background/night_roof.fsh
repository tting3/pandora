#ifdef GL_ES
precision highp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;


void main()
{
	vec4 v_orColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);

	float gray = dot(v_orColor.rgb,vec3(0.299,0.587,0.114))*0.6;
	gl_FragColor = vec4(v_orColor.r*0.4+gray-0.588,v_orColor.g*0.4+gray-0.588,v_orColor.b*0.4+gray-0.588,v_orColor.a);
}
