// Mixes color with luma-coefficient grayscale
vec3 colorMix(vec3 color, float time) {
    float gray = dot(color, vec3(0.2126, 0.7152, 0.0722));
    return mix(vec3(gray), color, time);
}

// Main
void main(void) {
    float time = fract(u_time/u_duration);
    
    vec4 texture = texture2D(u_texture, v_tex_coord);
    
    // Mixed color
    vec3 color = colorMix(texture.rgb, time);
    
    float num = sin(360.0*(1.0-time))*256.0;
    float line = floor(num*v_tex_coord.y);
    float bin = mod(line, 2.0);
    
    vec4 almost = mix(vec4(color, texture.a)*time, texture*vec4(bin), bin);
    
    if (almost.a <= 0.2) {
        almost.a = 0.0;
    }
    
    gl_FragColor = vec4(almost.rgb + vec3(0,(1.0-time)*0.25,(1.0-time)*0.5) * almost.a, almost.a);
}
