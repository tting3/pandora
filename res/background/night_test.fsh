#ifdef GL_ES
precision highp float;
#endif

#define RADIUS 70000.0

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

uniform vec2 ratio;
uniform int lights_num;
uniform vec2 light0;
uniform vec2 light1;
uniform vec2 light2;
uniform vec2 light3;
uniform vec2 light4;

void main()
{
	vec4 v_orColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);
	vec2 texcoord = gl_FragCoord.xy * ratio.xy;
	vec2 lights[5];
	lights[0] = light0;
	lights[1] = light1;
	lights[2] = light2;
	lights[3] = light3;
	lights[4] = light4;
	if(texcoord.x > lights[0].x && texcoord.y > lights[0].y){
		float gray = dot(v_orColor.rgb,vec3(0.299,0.587,0.114))*0.56;
		gl_FragColor = vec4(v_orColor.r*0.44+gray-0.2,v_orColor.g*0.44+gray-0.2,v_orColor.b*0.44+gray-0.2,v_orColor.a);
	}
	else{
		float gray = dot(v_orColor.rgb,vec3(0.299,0.587,0.114))*0.6;
		gl_FragColor = vec4(v_orColor.r*0.4+gray-0.588,v_orColor.g*0.4+gray-0.588,v_orColor.b*0.4+gray-0.588,v_orColor.a);
	}
}
