// ノーマルマップの適用
Shader "Custom/Sample6-1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Normal] _NormalMap ("Normal map", 2D) = "bump" {}
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
                float2 uv       : TEXCOORD0;

                // 頂点シェーダーの入力に接ベクトルと従ベクトルを追加
                // float3 tangent : TANGENT;
            };

            // ピクセルシェーダーへの入力
            struct v2f
            {
                float4 vertex      : SV_POSITION;
                float2 uv       : TEXCOORD0;

                // ピクセルシェーダーの入力に接ベクトルと従ベクトルを追加
                // float3 tangent  : TANGENT;      // 接ベクトル
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            sampler2D _NormalMap;

            /// モデル用の頂点シェーダーのエントリーポイント
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                return o;
            }

            /// モデル用のピクセルシェーダーのエントリーポイント
            float4 frag(v2f i) : SV_Target0
            {
                half3 normal = UnpackNormal(tex2D(_NormalMap, i.uv));
                normal = normalize(normal);

                // タンジェントスペースの法線を0～1の範囲から-1～1の範囲に復元する

                float3 ambientLig = 0;
                ambientLig.x += 0.3f;
                ambientLig.y += 0.3f;
                ambientLig.z += 0.3f;
                
                Light light = GetMainLight();
                float3 lig = 0.0f;
                lig += max(0.0f, dot(normal, -light.direction)) * light.color;
                lig += ambientLig;

                float4 finalColor = _MainTex.Sample(sampler_MainTex, i.uv);

                // 最終出力カラーに光を乗算する
                finalColor.xyz *= lig;

                return finalColor;
            }
            
            ENDHLSL
        }
    }
}
