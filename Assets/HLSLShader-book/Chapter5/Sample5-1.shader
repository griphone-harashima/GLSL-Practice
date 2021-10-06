// 複数ライトの適用
Shader "Custom/Sample5-1"
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
                 float3 worldPos : TEXCOORD1;
            };

            float3 CalcLamberDiffuse(float3 lightDirection, float3 lightColor, float3 normal);
            float3 CalcPhongSpecular(float3 lightDirection, float3 lightColor, float3 worldPos, float3 normal);

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.normal = v.normal;
                o.worldPos = v.vertex.xyz;

                return o;
            }

            float4 frag(v2f i) :SV_Target0
            {
                Light light = GetMainLight();
                float3 diffDirection = CalcLamberDiffuse(light.direction, light.color, i.normal);
                float3 specDirection = CalcPhongSpecular(light.direction, light.color, i.worldPos, i.normal);

                uint lightsCount = GetAdditionalLightsCount();
                float3 diffPoint = 0;
                float3 specPoint = 0;
                for(uint lightIndex = 0u; lightIndex < lightsCount; ++lightIndex)
                {
                    Light l = GetAdditionalLight(lightIndex, i.worldPos);

                    diffPoint += CalcLamberDiffuse(l.direction, l.color, i.normal) * l.distanceAttenuation;
                    specPoint += CalcPhongSpecular(l.direction, l.color, i.worldPos, i.normal) * l.distanceAttenuation;
                }

                float3 diffuseLig = diffPoint + diffDirection;
                float3 specularLig = specPoint + specDirection;

                float3 ambientLig = 0;
                ambientLig.x += 0.3f;
                ambientLig.y += 0.3f;
                ambientLig.z += 0.3f;

                float3 lig = diffuseLig + specularLig + ambientLig;
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
            
            ENDHLSL
        }
    }
}
