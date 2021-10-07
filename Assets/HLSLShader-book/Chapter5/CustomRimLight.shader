Shader "Custom/CustomRimLight"
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

            struct appdata
             {
                 float4 vertex : POSITION;
                 float3 color : COLOR;
                 float3 normal : NORMAL;
             };
     
             struct v2f {
                 float4 pos : SV_POSITION;
                 float3 normal : NORMAL;
                 float4 posWorld : TEXCOORD0;
                 float3 color : COLOR;
             };

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
     
                 o.pos = TransformObjectToHClip(v.vertex.xyz);
             
                 o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                 o.normal = normalize( mul ( float4(v.normal, 0.0), unity_WorldToObject).xyz);
     
                 o.color = v.color;
     
                 return o;
             }
     
             half4 frag(v2f i) : COLOR
             {
                 float3 normalDir = i.normal;
                 float3 viewDir = normalize( _WorldSpaceCameraPos.xyz - i.posWorld.xyz);
                 
                 float rim = 1 - saturate( dot(viewDir, normalDir) );
     
                 float3 rimLight = pow(rim, _RimPower) * _RimColor;
     
                 return float4( i.color.xyz + rimLight, 1.0f);
             }
            
            ENDHLSL
        }
    }
}
