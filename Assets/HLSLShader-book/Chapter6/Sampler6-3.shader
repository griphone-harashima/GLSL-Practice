// スペキュラマップの適用
Shader "Custom/Sample6-3"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [Normal] _NormalMap ("Normal map", 2D) = "bump" {}
        _SpecularMap ("Specular map", 2D) = "bump" {}
        _AOMap ("AO map", 2D) = "bump" {}
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
                float3 worldPos : TEXCOORD1;
            };

            float3 CalcLambertDiffuse(Light light, half3 normal);
            float3 CalcPhongSpecular(Light light, float3 normal, float3 worldPos);

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            sampler2D _NormalMap;
            // sampler2D _SpecularMap;
            TEXTURE2D(_SpecularMap);
            SAMPLER(sampler_SpecularMap);
            TEXTURE2D(_AOMap);
            SAMPLER(sampler_AOMap);

            /// モデル用の頂点シェーダーのエントリーポイント
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = v.vertex.xyz;

                return o;
            }

            /// モデル用のピクセルシェーダーのエントリーポイント
            float4 frag(v2f i) : SV_Target0
            {
                Light light = GetMainLight();
                half3 normal = UnpackNormal(tex2D(_NormalMap, i.uv));
                normal = normalize(normal);

                float3 directionLig = CalcLambertDiffuse(light, normal);
                float3 specularLig = CalcPhongSpecular(light, normal, i.worldPos) * 10.0f;

                float3 specPower = _SpecularMap.Sample(sampler_SpecularMap, i.uv);
                specularLig *= specPower;

                float3 ambientLig = 0;
                ambientLig.x += 0.3f;
                ambientLig.y += 0.3f;
                ambientLig.z += 0.3f;
                float ambientPower = _AOMap.Sample(sampler_AOMap, i.uv);
                ambientLig *= ambientPower;
                
                float3 lig = ambientLig + specularLig + directionLig;
                
                float4 finalColor = _MainTex.Sample(sampler_MainTex, i.uv);

                // 最終出力カラーに光を乗算する
                finalColor.xyz *= lig;

                return finalColor;
            }

            float3 CalcLambertDiffuse(Light light, half3 normal)
            {
                return max(0.0f, dot(normal, -light.direction)) * light.color;
            }

            float3 CalcPhongSpecular(Light light, float3 normal, float3 worldPos)
            {                
                // 反射ベクトルを求める
                float3 refVec = -reflect(light.direction, normal);
                // 光が当たったサーフェイスから視点に伸びるベクトルを求める
                float3 toEye = _WorldSpaceCameraPos - worldPos;
                toEye = normalize(toEye);

                // 鏡面反射の強さを求める
                float t = saturate(dot(refVec, toEye));

                // 鏡面反射の強さを絞る
                t = pow(t, 5.0f);

                // 鏡面反射光を求める
                return  light.color * t;
            }
            
            ENDHLSL
        }
    }
}