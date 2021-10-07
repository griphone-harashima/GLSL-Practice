// 半球ライト
Shader "Custom/Sample5-4"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GroundColor ("GroundColor", Color) = (1,1,1,1)
        _SkyColor ("SkyColor", Color) = (1,1,1,1)
        _GroundNormal("GroundNormal", Vector) = (1,1,1)
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
                 float3 worldPos : TEXCOORD1;

                 float3 normalInView : TEXCOORD2; // カメラ空間の法線
            };

            float3 CalcLambertDiffuse(float3 lightDirection, float3 lightColor, float3 normal);
            float3 CalcPhongSpecular(float3 lightDirection, float3 lightColor, float3 worldPos, float3 normal);
            float3 CalcLigFromDirectionalLight(v2f i);

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            float3 _GroundColor;
            float3 _SkyColor;
            float3 _GroundNormal;
            
            v2f vert(appdata v)
            {
                 v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.normal = v.normal;
                o.worldPos = v.vertex.xyz;
                // カメラ空間の法線を求める
                o.normalInView = TransformObjectToWorldNormal(v.normal);

                return o;
            }

            float4 frag(v2f i) :SV_Target0
            {
                float3 directionLig = CalcLigFromDirectionalLight(i);
                float3 ambientLig = 0;
                ambientLig.x += 0.3f;
                ambientLig.y += 0.3f;
                ambientLig.z += 0.3f;

                // サーフェイスの法線と地面の法線との内積を計算する
                float t = dot(i.normal, _GroundNormal);

                // 内積の結果を0～1の範囲に変換する
                t = (t + 1.0f) / 2.0f;

                // 地面色と天球色を補完率tで線形補完する
                float3 hemiLight = lerp(_GroundColor, _SkyColor, t);

                // 各種ライトの反射光を足し算して最終的な反射光を求める
                float3 finalLig = directionLig + ambientLig;

                // step-5 半球ライトを最終的な反射光に加算する
                finalLig += hemiLight;
                float4 finalColor = _MainTex.Sample(sampler_MainTex, i.uv);

                // テクスチャカラーに求めた光を乗算して最終出力カラーを求める
                finalColor.xyz *= finalLig;

                return finalColor;
            }

            float3 CalcLamberDiffuse(float3 lightDirection, float3 lightColor, float3 normal)
            {
                float t = dot(normal, lightDirection);
                t = max(0.0f,t);
                return lightColor * t;
            }

            float3 CalcPhongSpecular(float3 lightDirection, float3 lightColor, float3 worldPos, float3 normal)
            {
                float3 refVec = -reflect(lightDirection, normal);
                float3 toEye = _WorldSpaceCameraPos - worldPos;
                toEye = normalize(toEye);

                float t = dot(refVec, toEye);
                t = max(0.0f, t);
                t = pow(t, 5.0f);

                return lightColor * t;
            }

            float3 CalcLigFromDirectionalLight(v2f i)
            {
                Light light = GetMainLight();
                float3 diffDirection = CalcLamberDiffuse(light.direction, light.color, i.normal);
                float3 specDirection = CalcPhongSpecular(light.direction, light.color, i.worldPos, i.normal);
                return diffDirection + specDirection;
            }
            
            ENDHLSL
        }
    }
}
