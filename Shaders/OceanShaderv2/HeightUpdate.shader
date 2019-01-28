Shader "Custom/HeightUpdate"
{
	Properties
	{
		_Velocity("velocities", 2D) = "black" {}
	}

		CGINCLUDE

#include "UnityCustomRenderTexture.cginc"

	static const float i_w = 1.0 / _CustomRenderTextureWidth;
	static const float i_h = 1.0 / _CustomRenderTextureHeight;
	static const float d_x = 1.0;
	static const float h_w = i_w / 2.0;
	static const float h_h = i_w / 2.0;
	static const float range = 30;

	sampler2D _Velocity; 
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

	float2 height_to_v(float2 uv) {
		return uv + float2(0, i_h / 2.0);
	}

	float select_upwind_pos(float velocity) {
		return velocity > 0 ? 0 : 1;
	}

	float select_upwind_neg(float velocity) {
		return velocity > 0 ? -1 : 0;
	}

	float4 frag(v2f_customrendertexture i) : SV_Target
	{
		float3 up = float3(0, i_h, 0);
		float3 right = float3(i_w, 0, 0);

		// depth
		float c = tex2D(_SelfTexture2D, i.localTexcoord);
		c = decode(c);

		float2 lv, rv, uv, dv;
		lv = decode(tex2D(_Velocity, height_to_u(i.localTexcoord - h_w)));
		rv = decode(tex2D(_Velocity, height_to_u(i.localTexcoord + h_w)));
		uv = decode(tex2D(_Velocity, height_to_v(i.localTexcoord + h_h)));
		dv = decode(tex2D(_Velocity, height_to_v(i.localTexcoord + h_h)));

		float d = c - (
			decode(tex2D(_SelfTexture2D, i.localTexcoord + select_upwind_pos(lv[0]) * right)) -
			decode(tex2D(_SelfTexture2D, i.localTexcoord + select_upwind_neg(rv[0]) * right)) +
			decode(tex2D(_SelfTexture2D, i.localTexcoord + select_upwind_pos(uv[1]) * up)) -
			decode(tex2D(_SelfTexture2D, i.localTexcoord + select_upwind_neg(dv[1]) * up)))
			/ d_x;

		return encode(d);
	}

		ENDCG

		SubShader
	{
		Cull Off ZWrite Off ZTest Always
			Pass
		{
			Name "Update"
			CGPROGRAM
#pragma vertex CustomRenderTextureVertexShader
#pragma fragment frag
			ENDCG
		}
	}
}
