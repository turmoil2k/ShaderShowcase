Shader "Unlit/TransparentGlowULS"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _DistTex ("Distort Texture", 2D) = "white" {}
        _MainColor ("Color", color) = (1,1,1,1)
        _CenterColor ("Center Color", color) = (0,0,0,1)
        _Vector ("Vec Dir", Vector) = (1,1,0,0)

        _BlurStrength("Blur Strength .1", Range(0, 0.2))= 0.1
        _EdgeOffset("Edge Offset -.6", Range(-2.0, 0.0)) = -0.6
        _EdgeShift("Edge Color Shift 1.25", Range(0, 2)) = 1.25
        _DistStrength("Distortion Strength 1",  Range(0.0, 3.0)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent"}
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off


        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            half4 _MainTex_ST;
            sampler2D _NoiseTex;
            half4 _NoiseTex_ST;
            sampler2D _DistTex;
            half4 _DistTex_ST;

            fixed4 _MainColor;
            fixed4 _CenterColor;

            half2 _Vector;

            half _BlurStrength;
            half _EdgeOffset;
            half _EdgeShift;
            half _DistStrength;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            half Band(float t, float start, float end, float blur)
            {
                float step1 = smoothstep(start-blur, start+blur, t);
                float step2 = smoothstep(end+blur, end-blur, t);

                return step1*step2;
            }

            half SinEdge(float amp, float time, float offset)
            {   
                return (amp * sin(time)) + offset;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half2 distTex = (tex2D(_DistTex, i.uv).xy * 2 - 1) * _DistStrength;//1 is amount
                half2 noiseUV = float2((i.uv + (_Vector.xy * _Time.y))+ distTex);
                //float2 noiseUV = float2((i.nuv + (_Vector.xy * _Time.y)));//+ distTex);
                //fixed4 col = tex2D(_NoiseTex, noiseUV);//noiseUV
                half noiseSample = tex2D(_NoiseTex, noiseUV).x;//noiseUV
                //float randomNoiseUV = noiseUV.r;

                half2 shiftedUV = (i.uv * 2 - 1) + (noiseSample * 0.5) - 0.125 ;// + (noiseSample - .225);// + noiseUV;
                //shiftedUV = length(shiftedUV);
                //shiftedUV += 0.2;
                //shiftedUV.x = step(shiftedUV.x,0.99);//sin(_Time.y));
                //shiftedUV.y = step(shiftedUV.y,0.99);
                half edgeShift = SinEdge(0.05, _Time.y * 2, _EdgeOffset);

                half mask = Band(shiftedUV.x, edgeShift, -edgeShift, _BlurStrength) * 
                Band(shiftedUV.y, edgeShift, -edgeShift, _BlurStrength);// * noiseUV.r;
                
                //float blurredArea = saturate

                // COMPLETED SQUARE THESE 4 LINES IGNORE MID
                //float3 color = (1,1,1) * 1 - mask; //* shiftedUV.x;
                _MainColor = lerp(_CenterColor, _MainColor, (length((i.uv * 2 - 1) * shiftedUV)) * _EdgeShift);
                _MainColor *= 1 - mask;

                //_MainColor = frac(_MainColor);
                //lerp()
                //clip((1 - mask) - 0.99); //cutting blur
                //clip(mask - 0.01); //cutting blur
                //IGNORE >>> _MainColor.xyz = abs(sin(_Time.y) * 0.5);
                //clip(color);// - 1);
                //float colorFull = _MainColor < 0.95 ? _MainColor : 0; // getting blur only must use white
                //return col;
                UNITY_APPLY_FOG(i.fogCoord, col);
                fixed4 col = tex2D(_MainTex, i.uv);//noiseUV
                return _MainColor * col;// * noiseSample;
                //return _MainColor;// * col;
            
                
                //clip(col - 0.1);
                //satura
                //return col;
                //return float4(color,1) * _MainColor;
                // apply fog
                //return col;
            }
            ENDCG
        }
    }
}
