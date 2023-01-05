Shader "Unlit/ULSkyboxSphere"
{
    Properties
    {
        _MainTex ("Stars Tex", 2D) = "white" {}     //x y z w  = 12 4 0 0
        _CloudTex ("Cloud Tex", 2D) = "white" {}    //6 2 0 0
        _RandNoiseTex ("Stars Random Noise Tex", 2D) = "white" {}   // 1 1 0 0 none
        _DistTex("Distorting Noise Tex", 2D) = "white" {}           // 1 1 0 0 none
        _ColorH("Horizon Col", color) = (0,0.82,0.82,1) 
        _ColorS("Sky Col", color) = (0.57,0,0.57,1)
        [HDR]_ColorC("Star Col", color) = (1,1,1,1)
        _ColorSun("Sun Col", color) = (1,1,1,1)
        [HDR]_ColorCloud("Cloud Color (Alpha included)", color) = (1,1,1,1)

        _Vector("XY>Star Noise Vector | Z>STAR SIZE", vector) = (0.02,0.01,10,0.04)
        _VectorS("Sun Clip Vector", vector) = (0.1,0,0,0)
        _a("color a inverse lerp", Range(-5,5)) = -5
        _b("color b inverse lerp", Range(-5,5)) = 2
        _SunSize("Sun Size", Range(0,1)) = 0.2
        _SunClipSize("Sun Clip Size", Range(0,1)) = 0.2
        

        _Offset2("Offset2", Range(-1,1)) = 0
    }
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "LightMode" = "ForwardBase"
            "PassFlags" = "OnlyDirectional" 
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #define PI 3.141592
            #define TAU 6.283185

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD2;
                float3 viewDir : TEXCOORD3;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _CloudTex;
            float4 _CloudTex_ST;

            sampler2D _RandNoiseTex;

            sampler2D _DistTex;

            half4 _ColorH;
            half4 _ColorS;
            half4 _ColorC;
            half4 _ColorSun;
            half4 _ColorCloud;

            half4 _Vector;
            half4 _VectorS;

            half _a;
            half _b;
            half _SunSize;
            half _SunClipSize;
            half _Offset2;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld,v.vertex);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //o.uv = TRANSFORM_TEX(v.uv, _CloudTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float InverseLerp(float a, float b, float t)
            {
                return (t-a)/(b-a);
            }

            float2 Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset)
            {
                return UV * Tiling + Offset;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = normalize(i.worldPos);
                float skyY = (asin(worldPos.y)/(PI/2)); //y
                float skyX = (atan2(worldPos.x,worldPos.z)/TAU); //x
                float2 skyUV = float2(skyX,skyY);

                _MainTex_ST.zw += (_Time.y * _Vector.xy);
                //_RandNoiseTex_ST.z += (_Time.y * _Vector.w);

                //tilling & offset / UV SETTERS
                float2 skyUVST = Unity_TilingAndOffset_float(skyUV,_MainTex_ST.xy,_MainTex_ST.zw);
                float2 cloudUVST = Unity_TilingAndOffset_float(worldPos.xz,_CloudTex_ST.xy,_CloudTex_ST.zw);
                float2 noiseUVST = skyUV;
                noiseUVST.x += (_Time.y * _Vector.w);
                //Sampling the Texture && Stars Movement
                float4 starTex = 1 - tex2D(_MainTex,skyUVST);// (i.uv + (_Vector.xy * _Time.y)));
                
                float2 distCol = tex2D(_DistTex,skyUV)*1;
                float noiseCol = pow(tex2D(_RandNoiseTex,noiseUVST + distCol.xy),2);//control 2 for amt of stars
                //Stars Creation change z for brightness power    //sin(_Time.y/2)|* (noiseCol.r))
                float maskTop = lerp(float4(1,1,1,1),float4(0.1,0.1,0.1,1),worldPos.y*10-9);
                starTex = pow(saturate(starTex),_Vector.z) * (_ColorC  * noiseCol) * maskTop;//(sin(_Time.y*4) * 10 + _Vector.z)) * _ColorC;
                //starTex = pow(saturate(starTex),round(sin(_Time.y) * 5 + _Vector.z)) * (_ColorC * (noiseCol.r));

                // Apply Fog Default
                UNITY_APPLY_FOG(i.fogCoord, col);

                //Lerping Colors
                float lerpUV = InverseLerp(_a,_b,i.uv.y) + _Offset2;
                float4 finalColorLerp = lerp(_ColorH, _ColorS, saturate(lerpUV));

                //Sun
                float3 worldSun = acos(dot(-_WorldSpaceLightPos0,normalize(i.viewDir)));
                float3 clipSun = acos(dot(normalize(_VectorS - _WorldSpaceLightPos0),normalize(i.viewDir)));
                float4 stepSun = float4(1 - step(_SunSize,worldSun),1);
                float4 stepclipSun = float4(1 - step(_SunClipSize,clipSun),1);
                float4 finalSuns = saturate(stepSun - stepclipSun) * _ColorSun;
                //Alwin first showed me the 2 circle clip method haha

                //Clouds // 1 is scale OR USE TILING samething => cloudUVST = 1 * (cloudUVST / worldPos.y);
                cloudUVST = (cloudUVST / worldPos.y) + (0.1 * _Time.y);
                //float4 colorBand = lerp(float4(0,0,0,1),float4(1,1,1,1),i.uv.y - 0.95)*lerp(float4(1,1,1,1),float4(0,0,0,1),i.uv.y - 0.95);
                float4 cloudsTex = (tex2D(_CloudTex,cloudUVST) * 1) * (_ColorCloud);
                //clip(cloudsCol-0.2);
                //return float4(worldPos.yyy * _ColorCloud.xyz,1);

                float cloudMask = pow(max(worldPos.y,0),2) * cloudsTex.a;//float(pow(max(worldPos.y,0),3)) * cloudsTex.a;
                float4 finalClouds = cloudMask * cloudsTex;
                
                
                //colorBand *= lerp(float4(1,1,1,1),float4(0,0,0,1),i.uv.y - 0.95);
                //return lerp(float4(1,1,1,1),float4(0,0,0,1),i.uv.y - 0.99);
                //float cloudColAlpha = pow(worldPos.y,3) * cloudsCol.a; //distance fade power?
                //return float4(cloudsCol.xyza * cloudColAlpha);
                //float4 finalClouds = float4(cloudsTex.rgb,float(pow(max(worldPos.y,0),3)) * cloudsTex.a);
                //return noiseCol;
                //return starTex;
                //return cloudsCol;

                return starTex + finalColorLerp + (finalSuns + finalClouds);//+ 1;// + cloudsTex;
                //return fixed4(i.worldPos,1);// * lerpUV;// return (col * mainCol);
            }
            ENDCG
        }
    }
}
