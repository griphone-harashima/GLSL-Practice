Shader "Custom/Sample4-3"
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

                o.worldPos = v.vertex.xyz;

                return o;
            }

           /// モデル用のピクセルシェーダーのエントリーポイント
            float4 frag(v2f i) : SV_Target0
            {
                Light light = GetMainLight();
                
                // step-7 ピクセルの法線とライトの方向の内積を計算する
                float t = dot(i.normal, light.direction);

                // // 内積の結果に-1を乗算する
                // t *= -1.0f;

                // step-8 内積の結果が0以下なら0にする
                t = max(0, t);

                // step-9 ピクセルが受けているライトの光を求める
                float3 diffuseLig = light.color * t;

                // 反射方向逆だったので"-"付けた
                float3 refVec = -reflect(light.direction, i.normal);
                float3 toEye = _WorldSpaceCameraPos - i.worldPos;
                toEye = normalize(toEye);

                // 鏡面反射の強さを求める
                t = dot(refVec, toEye);
                t = max(0, t);
                // 鏡面反射の強さを絞る
                t = pow(t, 5.0f);

                // 鏡面反射光を求める
                float3 specularLig = light.color * t;
                float3 lig = diffuseLig + specularLig;

                // 拡散反射光と鏡面反射光を足し算して、最終的な光を求める
                float4 finalColor = _MainTex.Sample(sampler_MainTex, i.uv);

                // step-10 最終出力カラーに光を乗算する
                finalColor.xyz *= lig;

                return finalColor;
            }
           
           ENDHLSL
        }
    }
}
