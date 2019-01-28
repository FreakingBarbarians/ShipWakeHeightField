Shader "Custom/DisplacementInput"
{
	Properties
	{
		
	}

		CGINCLUDE

#include "UnityCustomRenderTexture.cginc"

	float4 frag(v2f_customrendertexture i) : SV_Target
	{
		return float4(1, 1, 1, 1);
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
