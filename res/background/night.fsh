#ifdef GL_ES
precision highp float;
#endif

varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

uniform vec2 light0;
uniform vec2 light1;
uniform vec2 light2;
uniform vec2 light3;
uniform vec2 light4;
uniform int lights_num;
uniform float radius;

void main()
{
	vec4 v_orColor = v_fragmentColor * texture2D(CC_Texture0, v_texCoord);
	if(v_orColor.a == 0.0){
		gl_FragColor = vec4(v_orColor.r,v_orColor.g,v_orColor.b,v_orColor.a);
		return;
	}
	vec2 texcoord = gl_FragCoord.xy;
	float root = radius;
	vec2 lights[5];
	lights[0] = light0;
	lights[1] = light1;
	lights[2] = light2;
	lights[3] = light3;
	lights[4] = light4;
	int i;
	for(i = 0; i < lights_num; i++){
		float temp_root = (texcoord.x - lights[i].x)*(texcoord.x - lights[i].x)+(texcoord.y - lights[i].y)*(texcoord.y - lights[i].y);
		if(temp_root < root){
			root = temp_root;
		}
	}
	if(root < (radius / 2.0)){
		float gray = dot(v_orColor.rgb,vec3(0.299,0.587,0.114))*0.56;
		gl_FragColor = vec4(v_orColor.r*0.44+gray-0.588*root/radius,v_orColor.g*0.44+gray-0.588*root/radius,v_orColor.b*0.44+gray-0.588*root/radius,v_orColor.a);
	}
	else if(root < radius){
		float gray = dot(v_orColor.rgb,vec3(0.299,0.587,0.114))*0.58;
		gl_FragColor = vec4(v_orColor.r*0.42+gray-0.588*root/radius,v_orColor.g*0.42+gray-0.588*root/radius,v_orColor.b*0.42+gray-0.588*root/radius,v_orColor.a);
	}
	else{
		float gray = dot(v_orColor.rgb,vec3(0.299,0.587,0.114))*0.6;
		gl_FragColor = vec4(v_orColor.r*0.4+gray-0.588,v_orColor.g*0.4+gray-0.588,v_orColor.b*0.4+gray-0.588,v_orColor.a);
	}
}
