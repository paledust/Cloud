Shader "CloudFX/Cg_ParticleCloud"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Tint("Tint Color", Color) = (1,1,1,1)
		_EmissionMap("Emission", 2D) = "white"{}
		_EmissionColor("Emission Color", Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True"}
		LOD 100

		Pass
		{
			Blend One OneMinusSrcAlpha
			ZWrite Off
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 color: TEXCOORD1;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			sampler2D _EmissionMap;
			float4 _EmissionColor;
			float4 _MainTex_ST;
			float4 _Tint;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				fixed4 emit = tex2D(_EmissionMap, i.uv).r * _EmissionColor;
				fixed3 tint_RGB = _Tint.rgb * i.color.rgb;
				

				col.rgb *= tint_RGB;
				col.rgb += emit.rgb;
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				//Premultiply Alpha Blending
				float alpha = col.a * i.color.a * _Tint.a;
				col.rgb *= alpha;
				col.a = alpha;
				
				return col;
			}
			ENDCG
		}
	}
}
