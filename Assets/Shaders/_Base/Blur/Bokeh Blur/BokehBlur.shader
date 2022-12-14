Shader "Practical-URP/PostProcessing/Bokeh Blur"
{

    Properties
    {
        _MainTex ("MainTex", 2D) = "white" { }
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
        CBUFFER_END

        half _NearDis;
        half _FarDis;
        float _BlurSmoothness;
        float _Iteration;
        float _Radius;
        
        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);
        TEXTURE2D(_SourceTex);
        SAMPLER(sampler_SourceTex);
        SAMPLER(_CameraDepthTexture);

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

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o. texcoord = i. texcoord;
                return o;
            }

            half4 frag(v2f i) : SV_TARGET
            {
                float sprialRadian = radians(137.5f);
                float2x2 rotateMatrix = float2x2(cos(sprialRadian), -sin(sprialRadian), sin(sprialRadian), cos(sprialRadian));
                float2 uvPos = float2(_Radius, 0);
                float2 uv;
                float r;
                real4 tex = 0;

                for (int iter = 0; iter < _Iteration; iter++)
                {
                    r = sqrt(iter);
                    uvPos = mul(rotateMatrix, uvPos);
                    uv = i.texcoord + _MainTex_TexelSize.xy * uvPos * r;
                    tex += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                }
                return tex / (_Iteration - 1);
            }
            ENDHLSL
        }
        
        pass
        {

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.positionOS.xyz);
                o. texcoord = i. texcoord;
                return o;
            }

            half4 frag(v2f i) : SV_TARGET
            {
                float depth = Linear01Depth(tex2D(_CameraDepthTexture, i.texcoord).x, _ZBufferParams).x;
                real4 blur = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
                real4 Sour = SAMPLE_TEXTURE2D(_SourceTex, sampler_SourceTex, i.texcoord);
                _NearDis *= _ProjectionParams.w;
                _FarDis *= _ProjectionParams.w;
                float dis = 1 - smoothstep(_NearDis, saturate(_NearDis + _BlurSmoothness), depth);
                dis += smoothstep(_FarDis, saturate(_FarDis + _BlurSmoothness), depth);
                real4 combine = lerp(Sour, blur, dis);
                return combine;
            }
            ENDHLSL
        }
    }
}