#ifdef GL_ES
precision highp float;
#endif

int screen_width = 24;
int screen_height = 16;
uniform float shader_zoom;
uniform vec2 resolution;
uniform vec4 night_color;
uniform vec2 light_pos[10];
uniform float light_lenght[10];
uniform float light_glare_lenght[10];
uniform float light_all_length[10];
uniform float light_all_length_sq[10];
uniform float light_glare_lenght_sq[10];
uniform int light_count;
uniform float screen_zoom;
uniform float screen_mapping[24 * 16];
//uniform sampler2D screen_mapping;

float po_2_light_lenght[10];

void main(void)
{
    float f = 1.0;

    int i = 0;
    vec2 p;
    float color;
    float color_f;
    float length_sq;
    float length_f;
    
    int type = 0;
    
    int x = int(gl_FragCoord.x / screen_zoom / shader_zoom);
    int y = int(gl_FragCoord.y / screen_zoom / shader_zoom);
    
//    f = screen_mapping[y * screen_width + x];

    while (i < light_count)
    {
        if(screen_mapping[y * screen_width + x] == 1.0)
        {
            break;
        }
        
        if(f == 0.0)
        {
            break;
        }
        
        p = gl_FragCoord.xy - light_pos[i].xy;

        length_sq = dot(p, p);
        

        if(length_sq >= light_all_length_sq[i])
        {
            i++;
            continue;
        }
        
        if(length_sq <= light_glare_lenght_sq[i])
        {
            f = 0.0;
            i++;
            continue;
        }
        
        color = length(p) - light_glare_lenght[i];
        color_f = clamp(color / light_lenght[i], 0.0, 1.0);
        
        if(color_f < f)
        {
            f = color_f;
        }
        
        i++;
    }

    gl_FragColor = vec4(f * night_color);
}
