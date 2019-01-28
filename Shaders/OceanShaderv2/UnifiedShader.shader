	Shader "Custom/UnifiedUpdate"
	{
		Properties
		{
			_InputWaves("InputWaves", 2D) = "white" {}
			_InputHeight("InputHeight", 2D) = "black" {}
			_MousePos("MousePos", Vector) = (0,0,0,0)
			_Pos("_Pos", Vector) = (0,0,0,0)
			_Dim("_Dim", Vector) = (0,0,0,0)
			_Wind("_Wind", Vector) = (0,0,0,0)
			_MouseDown("_MouseDown", int) = 0
		}

			CGINCLUDE

#include "UnityCustomRenderTexture.cginc"

		static const float i_w = 1.0 / _CustomRenderTextureWidth;
		static const float i_h = 1.0 / _CustomRenderTextureHeight;
		static const float d_x = 15;
		static const float h_w = i_w / 2.0;
		static const float h_h = i_h / 2.0;
		static const float range = 20;
		static const float g = 9.81;
		static const float delta_time = 0.2;
		float4 _MousePos;
		float4 _Pos;
		float4 _Dim;
		float4 _Wind;

		int _MouseDown;

		sampler2D _InputHeight;

		float2 local_to_world(float4 dim, float4 pos, float2 local_tex_coord) {
			float2 p = float2(local_tex_coord[0] * dim[0] - 0.5*dim[0], local_tex_coord[1] * dim[1] - 0.5*dim[1]);
			return float2(pos[0], pos[1]) + p;
		}

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

		float2 grid_height_u(float2 height_idx) {
			return height_idx + float2(-h_w, 0);
		}

		float2 grid_u_height(float2 u_idx) {
			return u_idx + float2(h_w, 0);
		}

		float2 grid_height_v(float2 height_idx) {
			return height_idx + float2(0, -h_h);
		}

		float2 grid_v_height(float2 v_idx) {
			return v_idx + float2(0, h_h);
		}

		int upwind(float velocity) {
			return velocity > 0 ? 0 : 1;
		}

		float delta_h(float2 in_coords) {
			float u, d, l, r;
			float du, dd, dl, dr;

			// working in v and u grids resp
			u = tex2D(_SelfTexture2D, in_coords + float2(0, i_h)).z;
			d = tex2D(_SelfTexture2D, in_coords).z;

			l = tex2D(_SelfTexture2D, in_coords).y;
			r = tex2D(_SelfTexture2D, in_coords + float2(i_w, 0)).y;

			u = decode(u);
			d = decode(d);
			l = decode(l);
			r = decode(r);

			du = tex2D(_SelfTexture2D, in_coords + float2(0,  i_h)).x;
			dd = tex2D(_SelfTexture2D, in_coords + float2(0, -i_h)).x;
			dl = tex2D(_SelfTexture2D, in_coords + float2(-i_w, 0)).x;
			dr = tex2D(_SelfTexture2D, in_coords + float2( i_w, 0)).x;

			return (-((du*u) - (dd*d) + (dr*r) - (dl*l)) / d_x)*delta_time;
		}

		float2 advect(float2 in_coords) {
			float2 here = tex2D(_SelfTexture2D, in_coords).yz;

			here.x = decode(here.x);
			here.y = decode(here.y);

			float interp_u = decode(tex2D(_SelfTexture2D, in_coords - float2(here.x, 0)*delta_time).y);
			float interp_v = decode(tex2D(_SelfTexture2D, in_coords - float2(0, here.y)*delta_time).z);
			return float2(interp_u, interp_v);
		}

		float2 delta_velocity(float2 in_coords) {
			float u_1 = decode(tex2D(_SelfTexture2D, in_coords));
			float u_0 = decode(tex2D(_SelfTexture2D, in_coords - float2(i_w, 0)));

			float v_1 = decode(tex2D(_SelfTexture2D, in_coords));
			float v_0 = decode(tex2D(_SelfTexture2D, in_coords - float2(0, i_h)));

			return float2(u_1 - u_0, v_1 - v_0) *(-g / d_x)*delta_time;
		}

		float4 frag(v2f_customrendertexture i) : SV_Target
		{
			float h = tex2D(_SelfTexture2D, i.localTexcoord).x;
			h += delta_h(i.localTexcoord);
			float2 velocity = advect(i.localTexcoord);
			velocity += delta_velocity(i.localTexcoord);
			velocity = encode(velocity);
			float input = tex2D(_InputHeight, i.localTexcoord).x;
			if (_MouseDown && length(_MousePos.xy - local_to_world(_Dim, _Pos, i.localTexcoord).xy) < 3) {
				h = range;
			}
			h = max(input*range, h);
			return float4(h, velocity, 1);
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
