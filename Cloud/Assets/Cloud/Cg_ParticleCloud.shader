Shader "CloudFX/Cg_ParticleCloud"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Fade("Fading Strength",Range(0,10)) = 0
		_Tint("Tint Color", Color) = (1,1,1,1)
		_EmissionMap("Emission", 2D) = "white"{}
		_RimColor("Rim Color", Color) = (1,1,1,1)
		_RimSharpness("Rim Sharpness", Range(0,20)) = 0
		_RimIntensity("Rim Intensity",Range(1,2)) = 1
		_WobalTexture("Wobal Texutre", 2D) = "white"{}
		_WobalStrength("Wobal Strength", Float) = 1
		_WobalFreq("Wobal Frequency", Float) = 1
		_WobalIterate("Wobal Iteration", Range(0,20)) = 1
		_StrokeStrength("Stroke Strength", Range(0,1)) = 0
		[Toggle(SHOW_WOBAL)]_ShowWobal("Show Wobal Texture", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True" "LightModel"="ForwardBase"}
		LOD 100

		Pass
		{
			Blend One OneMinusSrcAlpha
			ZWrite Off
			Cull Off

			CGPROGRAM
			#pragma shader_feature SHOW_WOBAL
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 color : TEXCOORD1;
				fixed4 scrPos :TEXCOORD2;
				fixed2 cap : TEXCOORD3;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _WobalTexture;
			sampler2D _MainTex;
			sampler2D _EmissionMap;
			float4 _RimColor;
			float4 _MainTex_ST;
			float4 _Tint;
			float _WobalStrength;
			float _WobalFreq;
			float _Fade;
			float _StrokeStrength;
			float _RimSharpness;
			float _RimIntensity;
			int _WobalIterate;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.color = v.color;
				float4 pos = o.vertex;
				pos.z = 0;

				fixed3 worldNorm = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
				o.cap.xy = worldNorm.xy *.5+.5;

				o.scrPos = ComputeScreenPos(pos);

				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			float2 wobal_UV(float2 _uv, int iteration){
				for(int i=0;i<iteration;i++){
					float2 twist = tex2D(_WobalTexture, _uv + float2(0,_Time.y)*_WobalFreq).rg;
					twist *= tex2D(_WobalTexture, _uv + float2(0,_Time.y)*_WobalFreq*.5).rg;
					_uv.x += twist.x * _WobalStrength;
					_uv.y += twist.y * _WobalStrength;
				}

				return _uv;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				float2 uv = i.uv;
				uv = wobal_UV(i.uv,_WobalIterate);

				float2 wholeTwist = tex2D(_WobalTexture, 3*i.scrPos.xy/i.scrPos.w + float2(_Time.y,_Time.y)*_WobalFreq*.1).rg;
				wholeTwist *= tex2D(_WobalTexture, 1*i.scrPos.xy/i.scrPos.w - float2(_Time.y,_Time.y)*_WobalFreq*.5).rg;

				uv += wholeTwist*.1;

				fixed4 col = tex2D(_MainTex, uv);

				#ifdef SHOW_WOBAL
				col.rg = uv;
				col.b = 0;
				
				col.rgb *= col.a;
				return float4(wholeTwist,0,1);
				#endif

				float sharpness = clamp(pow(tex2D(_EmissionMap, uv).r,_RimSharpness+1),0,1);
				fixed4 emit = sharpness * _RimColor;
				fixed3 tint_RGB = _Tint.rgb * i.color.rgb;

				col.rgb = lerp(col.rgb * tint_RGB, _RimColor * _RimIntensity, sharpness);

				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				//Premultiply Alpha Blending
				float alpha = col.a * i.color.a * _Tint.a;
				alpha = clamp(pow(alpha,_Fade + 1),0,1);

				alpha = (col.a<_StrokeStrength)?0:alpha;

				col.rgb *= alpha;
				col.a = alpha;

				return col;
			}
			ENDCG
		}
	}
}
