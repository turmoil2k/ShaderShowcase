Shader "Unlit/ObjectMeshMarker"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalCut ("_NormalCut", Range(-1.0, 1.0)) = 0
        [HDR]_ColorA ("ColorA", color) = (1,1,1,1)
        [HDR]_ColorB ("ColorB", color) = (0.2,0.2,0.2,1)

        _Amp("Amp", Range(-100.0, 100.0)) = 40
        _AmpOS("AmpOffset", Range(-100.0, 100.0)) = 16
    }
    SubShader
    {
        Tags { "RenderType"="Transparent"
        "Queue" = "Transparent" }
        LOD 100

        Pass
        {

            Cull Off
            ZWrite Off
            //ZTest GEqual
            Blend One One

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
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD1;
                float3 normalTex : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _NormalCut;
            fixed4 _ColorA;
            fixed4 _ColorB;

            fixed _Amp;
            fixed _AmpOS;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                o.normalTex = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            #define TAU 6.283185307179586
            #define PI 3.141592653589793238

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);

                
                clip(-abs(i.normalTex.y) - _NormalCut);
                float offset = sin(i.uv.x * 3.141592653589793238 * _AmpOS) * 0.05;
                float xWave = sin((i.uv.y + offset - _Time.y * .2) * _Amp) * 0.5 + 0.5;// * abs(_Time))/20;
                xWave *= 1 - i.uv.y;
                
                float4 colorLerped = lerp(_ColorA,_ColorB*2,i.uv.y - 0.2);

                return xWave * colorLerped;

                //return float4(i.normalTex,1);
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                //return float4(i.uv,0,1);
            }
            ENDCG
        }
    }
}
