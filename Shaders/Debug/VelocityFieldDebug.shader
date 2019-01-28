// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/VelocityShader"
{
	Properties
	{
		_WaveTex("Wave Texture", 2D) = "white" {}
	[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
	_Color("Tint", Color) = (1,1,1,1)
		[MaterialToggle] PixelSnap("Pixel snap", Float) = 0
	}

		SubShader
	{
		Tags
	{
		"Queue" = "Transparent"
		"IgnoreProjector" = "True"
		"RenderType" = "Transparent"
		"PreviewType" = "Plane"
		"CanUseSpriteAtlas" = "True"
	}

		Cull Off
		Lighting Off
		ZWrite Off
		Blend One OneMinusSrcAlpha

		Pass
	{
		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile _ PIXELSNAP_ON
#include "UnityCG.cginc"

		struct appdata_t
	{
		float4 vertex   : POSITION;
		float4 color    : COLOR;
		float2 texcoord : TEXCOORD0;
	};

	struct v2f
	{
		float4 vertex   : SV_POSITION;
		fixed4 color : COLOR;
		float2 texcoord  : TEXCOORD0;
	};

	fixed4 _Color;
	sampler2D _WaveTex;

	static const float range = 20;
	static const float g = -9.81;

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

	float bezier(float t, float x0, float x1, float x2, float x3) {
		return pow(1 - t, 3) * x0 + 3 * t*pow(1 - t, 2) * x1 + 3 * pow(t, 2)*(1 - t)*x2 + pow(t, 3) * x3;
	}

	v2f vert(appdata_t IN)
	{
		v2f OUT;
		OUT.vertex = UnityObjectToClipPos(IN.vertex);
		OUT.texcoord = IN.texcoord;
		OUT.color = IN.color * _Color;
#ifdef PIXELSNAP_ON
		OUT.vertex = UnityPixelSnap(OUT.vertex);
#endif

		return OUT;
	}

	sampler2D _MainTex;
	sampler2D _AlphaTex;
	float _AlphaSplitEnabled;

	fixed4 SampleSpriteTexture(float2 uv)
	{
		fixed4 color = tex2D(_MainTex, uv);

#if UNITY_TEXTURE_ALPHASPLIT_ALLOWED
		if (_AlphaSplitEnabled)
			color.a = tex2D(_AlphaTex, uv).r;
#endif //UNITY_TEXTURE_ALPHASPLIT_ALLOWED

		return color;
	}

	fixed4 frag(v2f IN) : SV_Target
	{
		float4 c = float4(0,0,0,1);
		float4 b = tex2D(_WaveTex, IN.texcoord);
		// c.rgb *= c.a;
		// c.gb = abs(decode(b.gb)/range);
		if (decode(b.g) >= 0) {
			c.g = abs(decode(b.g));
			c.r = 0;
		}
		else {
			c.r = abs(decode(b.g));
			c.g = 0;
		}
		// c = b;
		return c;
	}
		ENDCG
	}
	}
}