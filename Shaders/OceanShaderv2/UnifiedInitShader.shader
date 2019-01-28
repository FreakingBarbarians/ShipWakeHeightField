Shader "Custom/UnifiedInitMaterial"
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

	static const float i_w = 1.0 / _CustomRenderTextureWidth;
	static const float i_h = 1.0 / _CustomRenderTextureHeight;
	static const float d_x = 30;
	static const float h_w = i_w / 2.0;
	static const float h_h = i_w / 2.0;
	static const float range = 20;
	static const float g = 9.81;

	sampler2D _InputWaves;
	static float rot = 0;

	// given a height grid pos (i, j) then the left and right velocities are
	// (i, j), (i + 1, j) resp.
	// given a height grid pos (i, j) then the down and up velocities are
	// (i, j), (i, j + 1) resp.

	//range -1000 to 1000
	float encode(float val) {
		return min(range * 2, max(0, val + range));
	}

	float decode(float val) {
		return val - range;
	}

	float2 encode(float2 val) {
		return float2(encode(val[0]), encode(val[1]));
	}

	float2 decode(float2 val) {
		return val - float2(range, range);
	}

	float4 encode(float4 val) {
		return float4(encode(val[0]), encode(val[1]), encode(val[2]), encode(val[3]));
	}

	float4 decode(float4 val) {
		return val - float4(range, range, range, range);
	}

	float2 height_to_u(float2 uv) {
		return uv + float2(i_w / 2.0, 0);
	}

	float2 u_to_height(float uv) {
		return 	uv - float2(i_w / 2.0, 0);
	}

	float2 height_to_v(float2 uv) {
		return uv + float2(0, i_h / 2.0);
	}

	float2 v_to_height(float2 uv) {
		return uv - float2(0, i_h / 2.0);
	}

	float select_upwind_pos(float velocity) {
		return velocity > 0 ? 0 : 1;
	}

	float select_upwind_neg(float velocity) {
		return velocity < 0 ? -1 : 0;
	}

	float2 rotate(float2 source, float amt) {
		return float2(cos(amt) * source.x - sin(amt)*source.y, sin(amt) * source.x + cos(amt) * source.y);
	}

	float spike(float t) {
		if (t % 10 > 1 && t % 10 < 5) {
			rot += unity_DeltaTime[0];
			return 0.05;
		}
		return 0;
	}

	float4 frag(v2f_init_customrendertexture IN) : COLOR
	{
		float4 c = tex2D(_Tex, IN.texcoord)*range;
		c.yz = range;
		return c;
	}
		ENDCG
	}
	}
}