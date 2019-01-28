Shader "Custom/WaveUpdateShader"
{
	Properties
	{
		_Wind("Wind", Vector) = (1, 0, 0, 0)
		_InputWaves("InputWaves", 2D) = "white" {}
	}

		CGINCLUDE

#include "UnityCustomRenderTexture.cginc"

	float4 _Wind;
	sampler2D _InputWaves;

	const static float decay_rate = 0.98;
	const static float q_damp = 0.05;
	const static float median = 0.5;
	const static float rand_damp = 0.003;
	const static float loss_coeff = 1;
	const static float pressure_coeff = 0.1;

	const static float2 dir_up = float2(0, 1);
	const static float2 dir_down = float2(0, -1);
	const static float2 dir_right = float2(1, 0);
	const static float2 dir_left = float2(-1, 0);

	const static float2 dir_up_left = float2(-0.70710678, 0.70710678);
	const static float2 dir_down_right = float2(0.70710678, -0.70710678);
	const static float2 dir_up_right = float2(0.70710678, 0.70710678);
	const static float2 dir_down_left = float2(-0.70710678, -0.70710678);

	static float rot = 0;

	float rand(float2 co) {
		return (frac(sin(dot(co.xy, float2(12.9898, 78.233))) + _Time[0] * 43758.5453));
	}

	float2 encode(float2 in_vec) {
		return float2(min(max(0, in_vec.x + 10), 20), min(max(0, in_vec.y + 10), 20));
	}

	float2 decode(float2 in_vec) {
		return float2(in_vec.x - 10, in_vec.y - 10);
	}

	float dir_coeff(float2 source, float2 source_dir) {
		source_dir = decode(source_dir);
		if (length(source_dir) > 0.3) {
			float2 d_norm = normalize(source_dir);
			return 0.125 + 0.125*dot(source, d_norm);
		}
		return 0.125;
	}

	float2 rotate(float2 source, float amt) {
		return float2(cos(amt) * source.x - sin(amt)*source.y, sin(amt) * source.x + cos(amt) * source.y);
	}

	float spike(float t) {
		if (t%10 > 1 && t%10 < 5) {
			return 0.05;
		}
		rot += unity_DeltaTime[0];
		return 0;
	}

	float4 frag(v2f_customrendertexture i) : SV_Target
	{

	float i_w = 1.0 / _CustomRenderTextureWidth;
	float i_h = 1.0 / _CustomRenderTextureHeight;

	float3 up = float3(0, i_h, 0);
	float3 right = float3(i_w, 0, 0);

	float4 c = tex2D(_SelfTexture2D, i.localTexcoord);

	float4 u = tex2D(_SelfTexture2D, i.localTexcoord + up);
	float4 d = tex2D(_SelfTexture2D, i.localTexcoord - up);
	float4 l = tex2D(_SelfTexture2D, i.localTexcoord - right);
	float4 r = tex2D(_SelfTexture2D, i.localTexcoord + right);
	float4 ul = tex2D(_SelfTexture2D, i.localTexcoord + up - right);
	float4 ur = tex2D(_SelfTexture2D, i.localTexcoord + up + right);
	float4 dl = tex2D(_SelfTexture2D, i.localTexcoord - up - right);
	float4 dr = tex2D(_SelfTexture2D, i.localTexcoord - up + right);

	// calculate loss percent
	float u_loss = (u[0] * loss_coeff) * dir_coeff(dir_down, u.yz);
	float d_loss = (d[0] * loss_coeff) * dir_coeff(dir_up, d.yz);
	float l_loss = (l[0] * loss_coeff) * dir_coeff(dir_right, l.yz);
	float r_loss = (r[0] * loss_coeff) * dir_coeff(dir_left, r.yz);
	float ul_loss = (ul[0] * loss_coeff) * dir_coeff(dir_down_right, ul.yz);
	float ur_loss = (ur[0] * loss_coeff) * dir_coeff(dir_down_left, ur.yz);
	float dl_loss = (dl[0] * loss_coeff) * dir_coeff(dir_up_right, dl.yz);
	float dr_loss = (dr[0] * loss_coeff) * dir_coeff(dir_up_left, dr.yz);
	
	c[0] = c[0] * (1 - loss_coeff);

	// add from neighbouring components

	c[0] += u_loss;
	c[0] += d_loss;
	c[0] += l_loss;
	c[0] += r_loss;
	c[0] += ul_loss;
	c[0] += ur_loss;
	c[0] += dl_loss;
	c[0] += dr_loss;
	// c[0] += 0.5 * unity_DeltaTime[0] * tex2D(_InputWaves, rotate(i.localTexcoord, rot)) * spike(_Time[1]*2);

	// calculate vector as weighted average
	float2 vel = decode(c.yz);
	float loss_max = u_loss + d_loss + l_loss + r_loss + ur_loss + ul_loss + dr_loss + dl_loss;
	vel *= (0.80);
	// c[0] = max(c[0], length(vel) / 200);
	// vel += decode(u.yz)  * u_loss /loss_max + u_loss  * dir_down * pressure_coeff; // decode(u.yz)  * u_loss / loss_max; +
	// vel += decode(d.yz)  * d_loss /loss_max + d_loss  * dir_up* pressure_coeff; // decode(d.yz)  * d_loss / loss_max;  +
	// vel += decode(l.yz)  * l_loss /loss_max + l_loss  * dir_right * pressure_coeff; // decode(l.yz)  * l_loss / loss_max;   +
	// vel += decode(r.yz)  * r_loss /loss_max + r_loss  * dir_left * pressure_coeff; // decode(r.yz)  * r_loss / loss_max;   +
	// vel += decode(ur.yz) * ur_loss/loss_max + ur_loss * dir_down_left * pressure_coeff; // decode(ur.yz) * ur_loss / loss_max;  +
	// vel += decode(ul.yz) * ul_loss/loss_max + ul_loss * dir_down_right * pressure_coeff; // decode(ul.yz) * ul_loss / loss_max;  +
	// vel += decode(dr.yz) * dr_loss/loss_max + dr_loss * dir_up_left * pressure_coeff; // decode(dr.yz) * dr_loss / loss_max;  +
	// vel += decode(dl.yz) * dl_loss/loss_max + dl_loss * dir_up_right * pressure_coeff   ; // decode(dl.yz) * dl_loss / loss_max;  +
	vel = _Wind.xy;
	c.yz = encode(vel).xy;

	return c;
	}

		ENDCG
		/*



		half4 frag(v2f_customrendertexture i) : SV_Target
		{
		return 0;
		}

		EDNCG
		*/

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
