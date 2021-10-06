// 拡散反射光の追加
Shader "Custom/Sample4-2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // 頂点シェーダーへの入力
            struct appdata
            {
                float4 vertex      : POSITION;
                float3 normal   : NORMAL;
                float2 uv       : TEXCOORD0;
            };

            // ピクセルシェーダーへの入力
            struct v2f
            {
                float4 vertex      : SV_POSITION;
                float3 normal   : NORMAL;
                float2 uv       : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            /// モデル用の頂点シェーダーのエントリーポイント
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // step-6 頂点法線をピクセルシェーダーに渡す
                o.normal = v.normal; // 法線を回転させる

                return o;
            }

            /// モデル用のピクセルシェーダーのエントリーポイント
            float4 frag(v2f i) : SV_Target0
            {
                Light light = GetMainLight();
                
                // step-7 ピクセルの法線とライトの方向の内積を計算する
                float t = dot(i.normal, light.direction);

                // 内積の結果に-1を乗算する
                // t *= -1.0f;

                // step-8 内積の結果が0以下なら0にする
                if(t < 0.0f)
                {
                    t = 0.0f;
                }

                // step-9 ピクセルが受けているライトの光を求める
                float3 diffuseLig = light.color * t;

                float4 finalColor = _MainTex.Sample(sampler_MainTex, i.uv);

                // step-10 最終出力カラーに光を乗算する
                finalColor.xyz *= diffuseLig;

                return finalColor;
            }
            
            ENDHLSL
        }
    }
}
