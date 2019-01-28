Shader "Custom/WaveInit"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_Tex("InputTex", 2D) = "white" {}
	}

		SubShader
	{
		Lighting Off
		Blend One Zero

		Pass
	{
		CGPROGRAM
#include "UnityCustomRenderTexture.cginc"

#pragma vertex InitCustomRenderTextureVertexShader
#pragma fragment frag
#pragma target 3.0

	float4      _Color;
	sampler2D   _Tex;

	float2 encode(float2 in_vec) {
		return float2(min(max(0, in_vec.x + 10), 20), min(max(0, in_vec.y + 10), 20));
	}

	float2 decode(float2 in_vec) {
		return float2(in_vec.x - 10, in_vec.y - 10);
	}

	float4 frag(v2f_init_customrendertexture IN) : COLOR
	{
		float4 c = _Color * tex2D(_Tex, IN.texcoord.xy);
		// c.yz = encode(float2(sin(IN.texcoord.x * 30), sin(IN.texcoord.x * 30)));
		return c;
	}
		ENDCG
	}
	}
}