Shader "Practical-URP/GlitchSplit"
{

    Properties
    {
        [HideInInspector] _MainTex ("MainTex", 2D) = "white" { }
        [HideInInspector] _Intensity ("Intensity", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" }
        Cull Off ZWrite Off ZTest Always

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            float _Intensity;
        CBUFFER_END
        
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        struct a2v
        {
            float4 positionOS : POSITION;
            float2 texcoord : TEXCOORD;
        };

        struct v2f
        {
            float4 positionCS : SV_POSITION;
            float2 texcoord : TEXCOORD;
        };
        ENDHLSL

        pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            float cur(float x);

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o.texcoord = i.texcoord;
                return o;
            }

            half4 frag(v2f i) : SV_TARGET
            {
                float noise = cur(frac(_Time.y));
                half R = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord + float2(0.02, 0.04) * noise).x;
                half G = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord).y;
                half B = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord - float2(0.05, -0.07) * noise).z;
                real4 mainTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
                real4 SplitRGB = real4(R, G, B, 1);
                return SplitRGB;

                float2 center = i.texcoord * 2 - 1;
                float mask = saturate(dot(center, center));
                mask = lerp(0, mask, _Intensity);

                SplitRGB = lerp(mainTex, SplitRGB, mask);
                return SplitRGB;
            }

            float cur(float x)
            {
                return -4.71 * pow(x, 3) + 6.8 * pow(x, 2) - 2.65 * x + 0.13 + 0.8 * sin(48.15 * x - 0.38);
            }

            ENDHLSL
        }
    }
}