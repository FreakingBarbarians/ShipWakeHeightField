// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
// Bezier curve eqn
// f(t) = (1-t)^3 p1_y + 3t(1-t)^2 p2_y + 3t^2 (1-t) p3_y + t^3 p4_y

// = pow(1-t, 3) * p1_y + 3*t*pow(1-t, 2) * p2_y + 3*pow(t,2)*(1-t)*p3_y + pow(t,3) * p4_y

Shader "Custom/SailShader"
{
	Properties
	{
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
	_Color("Tint", Color) = (1,1,1,1)
		[MaterialToggle] PixelSnap("Pixel snap", Float) = 0
	_SailStrength("SailStrength", Float) = 0
	_Center("Center", Vector) = (0,0,0,1)
	_Extent("Extent", Vector) = (1,1,1,1)
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

	float bezier(float t, float x0, float x1, float x2, float x3) {
		return pow(1 - t, 3) * x0 + 3 * t*pow(1 - t, 2) * x1 + 3 * pow(t,2)*(1 - t)*x2 + pow(t,3) * x3;
	}

	static const float epsilon = 0.8;
	static const float PI = 3.141592;
		struct appdata_t
	{
		float4 vertex   : POSITION;
		float4 color    : COLOR;
		float2 texcoord : TEXCOORD0;
	};

	struct v2f
	{
		float4 objvert   : TEXCOORD2;
		float4 vertex   : SV_POSITION;
		fixed4 color : COLOR;
		float2 texcoord  : TEXCOORD0;
		float dist : TEXCOORD1;
	};

	fixed4 _Color;
	float4 _Center;
	float4 _Extent;
	float _SailStrength;
	v2f vert(appdata_t IN)
	{
		v2f OUT;
		// flip
		float4 vertex = IN.vertex;
		vertex.y = _Extent.y - vertex.y;
		OUT.vertex = UnityObjectToClipPos(vertex);
		OUT.dist = 1 - (vertex - _Center).y / _Extent.y;
		OUT.texcoord = IN.texcoord;
		OUT.color = IN.color * _Color;

		//OUT.dist = (worldPos - centerPos).y / extent.y;

		float sin_val = sin((vertex.x + _Extent.x) / (_Extent.x * 2 / (2 * PI)));

#ifdef PIXELSNAP_ON
		OUT.vertex = UnityPixelSnap(OUT.vertex);
#endif
		OUT.objvert = vertex;
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
		float2 tex = IN.texcoord;
		float dither = 0 ; //sin(_Time.z + IN.objvert.x) / (_Extent.y * 10);
		tex.y += dither;
		fixed4 c =  SampleSpriteTexture(tex) * IN.color;
		c.rgb *= c.a;
		
		float t = (IN.objvert.x + _Extent.x) / (2 * _Extent.x);
		t = sqrt(bezier(t, 0, 0.2, 0.2, 0));
		// spline
		if (IN.dist < epsilon) {
			if (bezier(t, 0, _Extent.y * _SailStrength * 1.33, _Extent.y * _SailStrength * 1.33, 0) + dither * 2 < IN.objvert.y) {
				c = 0;
			}
		}

		if (IN.dist <= epsilon && (IN.dist <= 1 - _SailStrength || IN.dist >= 1)) {
			c = 0;
		}

		if (IN.texcoord.x < 0.01 || IN.texcoord.x > 0.99) {
			c = 0;
		}

		return c;
	}
		ENDCG
	}
	}
}