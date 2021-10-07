// リムライト
Shader "Custom/Sample5-3"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RimColor ("RimColor", Color) = (1,1,1,1)
        _RimPower("RimPower", float) = 1.3
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

            float3 CalcLamberDiffuse(float3 lightDirection, float3 lightColor, float3 normal);
            float3 CalcPhongSpecular(float3 lightDirection, float3 lightColor, float3 worldPos, float3 normal);
            float3 CalcLigFromDirectionalLight(v2f i);

            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            float3 _RimColor;
            half _RimPower;

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

                Light light = GetMainLight();
                
                // サーフェイスの法線と光の入射方向に依存するリムの強さを求める
                float power1 = 1.0f - max(0.0f, dot(light.direction, i.normal));
                // サーフェイスの法線と視線の方向に依存するリムの強さを求める
                float power2 = 1.0f - max(0.0f, i.normalInView.z * -1.0f);
                float limPower = power1 * power2;
                limPower = pow(limPower, _RimPower);
                float3 limColor = limPower * _RimColor;

                float3 lig = directionLig + ambientLig;
                lig += limColor;
                float4 finalColor = _MainTex.Sample(sampler_MainTex, i.uv);
                finalColor.xyz *= lig;

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
