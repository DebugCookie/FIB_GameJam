shader_type canvas_item;

uniform float StripesNum = 9; //slider[1,10,100]
uniform float StripesAng = 45; //slider[-180,45,180]
uniform float StripesThinkness = 0.5; //slider[0,0.5,1]
uniform float CenterHole = 0.0; //slider[0,0.125,1]
uniform float OuterHole = 1; //slider[0,0.825,1]

vec2 cLog(vec2 z){
    return vec2(log(length(z)), atan(z.y, z.x));
}

    void fragment(){ 
        float pi = 3.141592653589793;
        vec2 p = UV.xy - vec2(0.5, 0.5); // correct to the center of texture
        float t = radians(StripesAng);
        float c = cos(t);
        float s = sin(t);
        mat2 m = mat2(vec2(c, -s), vec2(s, c));
        vec2 q = m * cLog(p);
        //vec2 q = cos(m * cLog(p)+TIME);
    	
        float color = float(mod((StripesNum * q.y / (sqrt(2.0) * pi))-TIME, 1.0) < StripesThinkness
            || length(p) < CenterHole
            || length(p) > OuterHole
        );
    	
    	vec3 color_final;
    	vec3 tex=texture(TEXTURE,UV).rgb;
    	
    	/* YOUR FORMULA MULTIPLY UV */
    	vec2 uv= UV*color; 
    		
    	/* MIX: */
    	//color_final=mix(vec3(color), tex, 0.5); 
    	
    	/* MIX IF WHITE = 1: */
    	//if (color == 1.0)
    	//	color_final=mix(vec3(color), tex, 0.9);
    
       //COLOR= vec4(vec3(color),1); //original
       //COLOR= vec4(color_final, 1.0); //mixes
    	COLOR= texture(TEXTURE,uv);	//modify uv to texture			
    }
